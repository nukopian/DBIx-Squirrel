# DBIx::Squirrel reference

<!-- stopwords: flatMap -->

DBI, minus the boilerplate, plus a pipeline.

With DBIx::Squirrel, you still write SQL, as you do with the DBI. It
takes away the friction around it: placeholders in whatever style you
like, iterators over results, rows as objects, and a pipeline of
transformations written beside the query. It's a subclass of the DBI,
so everything the DBI does still works. Where the two do the same
thing, they give the same result.

This reference describes every feature, with examples.
[The how-to](HOWTO.md) shows how to do common tasks, one recipe at a
time. Each module's own POD says the same things more briefly. Where
the two differ, the POD is the authority.

This is version 2, a rewrite of DBIx::Squirrel 1.x for Perl 5.36 or
later. [Upgrading from 1.x](#upgrading-from-1x) lists what changes for
code written for 1.x.

## Contents

- [At a glance](#at-a-glance)
- [Connecting](#connecting)
- [DBIx::Squirrel's own attributes](#dbixsquirrels-own-attributes)
- [Placeholders](#placeholders)
- [Preparing statements](#preparing-statements)
- [Binding and executing](#binding-and-executing)
- [do](#do)
- [The select methods](#the-select-methods)
- [Iterators](#iterators)
- [Result sets and row objects](#result-sets-and-row-objects)
- [Pipelines](#pipelines)
- [Stopping a pipeline](#stopping-a-pipeline)
- [Gathering: stages with state, and an end](#gathering-stages-with-state-and-an-end)
- [What a stage can ask: Context](#what-a-stage-can-ask-context)
- [pipe and tap on handles](#pipe-and-tap-on-handles)
- [Canned stages](#canned-stages)
- [Writing stages](#writing-stages)
- [A function for each database and statement: Sugar](#a-function-for-each-database-and-statement-sugar)
- [Errors](#errors)
- [Diagnostics](#diagnostics)
- [Differences from plain DBI](#differences-from-plain-dbi)
- [Upgrading from 1.x](#upgrading-from-1x)
- [The modules](#the-modules)

## At a glance

```perl
use v5.36;
use DBIx::Squirrel;

my $dbh = DBIx::Squirrel->connect($data_source, $username, $password, \%attr);

# Placeholders in the style you like: ?, ?1, :1, $1, :name or $name
my $sth = $dbh->prepare('SELECT * FROM artist WHERE id = :id OR name = :name');
$sth->execute(id => 1, name => 'AC/DC');

# A numbered placeholder takes one value, wherever it appears
my $row = $dbh->selectrow_hashref(
    'SELECT * FROM artist WHERE id = $1 OR parent_id = $1', undef, 2,
);

# A placeholder with "..." takes a list: a "?" for each of its values
my $rows = $dbh->selectall_arrayref(
    'SELECT * FROM artist WHERE id IN (...:ids)', ids => [1, 2, 3],
);

# An iterator over the results, each run through a pipeline of stages
my $names = $dbh->iterate(
    'SELECT name FROM artist WHERE name LIKE ?', 'A%',
    sub ($row) { $row->[0] },
);
while (my($name) = $names->next) {
    say $name;
}

# Ready-made stages, for the jobs that come up again and again
use DBIx::Squirrel::Stages::Flow;    # take, drop
use DBIx::Squirrel::Stages::Rows;    # pluck, as_hash
my @first_ten = $dbh->iterate('SELECT name FROM artist ORDER BY name', pluck('name'), take(10))->all;

# Each row as an object, with a method for each column
my $artist = $dbh->results('SELECT * FROM artist WHERE id = :id', id => 1)->single;
say $artist->name;

# A function for each database, and each statement, defined as the
# program compiles, so from the environment or literals
use DBIx::Squirrel::Sugar
    database  => {music => [$ENV{MUSIC_DSN}, $ENV{MUSIC_USER}, $ENV{MUSIC_PASS}]},
    statement => {artist_names => [music => 'SELECT name FROM artist', sub ($row) { $row->[0] }]};

my @names = artist_names;
```

## Connecting

### Importing

`use DBIx::Squirrel` takes the names the DBI exports, as `use DBI`
does. The DBI exports them:

```perl
use DBIx::Squirrel qw(:sql_types neat);
```

### connect

```perl
$dbh = DBIx::Squirrel->connect($data_source, $username, $password);
$dbh = DBIx::Squirrel->connect($data_source, $username, $password, \%attr);
$dbh = DBIx::Squirrel->connect($data_source, \%attr);
$dbh = DBIx::Squirrel->connect($dbh, \%attr);
```

`connect` connects to a data source, as the DBI's `connect` does, and
returns a database handle, a `DBIx::Squirrel::db`. Its statement handles
are `DBIx::Squirrel::st`s. Both are subclasses of the DBI's own, so they
do everything the DBI's handles do.

The username and password can be left out, with the attributes straight
after the data source.

Unlike the DBI's `connect`, it **always croaks** if the connection
fails, whatever `RaiseError` is set to. The message is the one the DBI
raises under `RaiseError`, such as
`DBIx::Squirrel connect('dbname=music.db','',...) failed: ...`, and
it's reported at the line that called `connect`. The DBI returns
`undef` without `RaiseError`.

### Connecting with an existing handle

Given a database handle in place of a data source, `connect` makes a
new connection with the same parameters, using the DBI's `clone`. Any
attributes passed are applied to the new connection. The handle can
come from DBIx::Squirrel, from the DBI itself, or from code that made
its own connection. So a plain DBI handle can be turned into
DBIx::Squirrel's:

```perl
my $plain = DBI->connect($data_source, $username, $password);
my $dbh   = DBIx::Squirrel->connect($plain);
```

The new handle keeps the first one's `ekorn_` defaults. Any passed take
their place. It's a separate connection, not a second name for the
first. It doesn't share the first one's transaction, temporary tables
or session settings. An in-memory SQLite database, for example, gives
a new, empty database.

### connect_cached

`connect_cached` is the DBI's own. It calls `connect` when it needs a
new connection, so it croaks on failure too. DBIx::Squirrel's own
attributes are part of the cache's key. Two calls with the same
attributes have the same handle, and calls with different ones don't.

### The dialect

Statements are read by the rules of the database they're for: where
strings start and end, and what's a comment (see
[Placeholders](#placeholders)). The dialect is given in the
`ekorn_dialect` attribute. When it isn't, `connect` works it out:

- It's the driver's own name, such as `SQLite`, `mysql` or `Pg`.
- A driver that passes the connection on to another database
  (DBD::ADO, DBD::Gofer, DBD::JDBC, DBD::ODBC or DBD::Proxy) is asked,
  through the DBI's `get_info`, what the database is. MariaDB, MySQL,
  PostgreSQL and SQLite are recognised.
- Any other database, or one that doesn't say, is read by the standard
  rules.

Name the dialect when `connect` can't tell:

```perl
# MySQL, through a driver that doesn't say what's behind it
$dbh = DBIx::Squirrel->connect($data_source, $username, $password, {
    ekorn_dialect => 'mysql',
});
```

### Subclassing

Called on a subclass of DBIx::Squirrel, `connect` uses that subclass's
database and statement handle classes. The DBI requires the subclass to
have both, and each must be a subclass of DBIx::Squirrel's:

```perl
package My::Squirrel     { our @ISA = 'DBIx::Squirrel' }
package My::Squirrel::db { our @ISA = 'DBIx::Squirrel::db' }
package My::Squirrel::st { our @ISA = 'DBIx::Squirrel::st' }

my $dbh = My::Squirrel->connect($data_source, $username, $password);
```

Without them, the DBI warns that the subclass isn't set up, and returns
its own handles.

## DBIx::Squirrel's own attributes

Attributes whose names start `ekorn_` are DBIx::Squirrel's own. They
aren't passed on to the DBI. Passed to `connect`, they're the defaults
for every statement the handle prepares. Passed to `prepare` (or
`prepare_cached`, `do`, `iterate` and the others), they override those
defaults for one statement.

| Attribute | What it does |
|---|---|
| `ekorn_dialect` | The driver whose rules statements are read by, such as `mysql` or `Pg`. `connect` works it out when it isn't given. See [The dialect](#the-dialect). |
| `ekorn_finish_active` | When true, a statement still active from an earlier `execute` is finished before it's executed again. See [execute](#execute). |
| `ekorn_slice` | The shape an iterator fetches rows in: an array reference for arrays (the default), or a hash reference for hashes. See [Rows as arrays or hashes](#rows-as-arrays-or-hashes). |
| `ekorn_result_class` | The base class of a result set's row objects, a subclass of `DBIx::Squirrel::Result`. See [Methods of your own](#methods-of-your-own). |

```perl
my $dbh = DBIx::Squirrel->connect($data_source, $username, $password, {
    RaiseError  => 1,
    ekorn_slice => {},           # iterators fetch hashes, by default
});

my $sth = $dbh->prepare($statement, {ekorn_slice => []});    # arrays, here
```

## Placeholders

### The styles

A statement can use placeholders in any of these styles. Each is
rewritten as `?` before the DBI sees it:

| Style | Example | How values are bound |
|---|---|---|
| `?` | `WHERE id = ?` | In order, as with the DBI. |
| `?1` | `WHERE id = ?1` | By number, from 1. |
| `:1` | `WHERE id = :1` | By number, from 1. |
| `$1` | `WHERE id = $1` | By number, from 1. |
| `:name` | `WHERE id = :id` | By name. |
| `$name` | `WHERE id = $id` | By name. |

A statement uses **one style** throughout. `prepare` croaks if it finds
more than one, listing each as an example:
`Expected one placeholder style, not several (?, :name)`.

The same placeholder can appear more than once:

- A **numbered** placeholder is bound once, wherever it appears. In
  `SELECT $2 + $1, $1`, the values `(10, 20)` give
  `SELECT 20 + 10, 10`. There must be as many values as the highest
  number, and numbers start from 1.
- A **named** placeholder is bound by name, wherever it appears. Values
  are given as pairs or in a hash reference, with or without the sigil.
  There must be a value for each name, and no other.

```perl
my $sth = $dbh->prepare('SELECT * FROM artist WHERE id = :id OR parent_id = :id');
$sth->execute(id => 2);
$sth->execute({':id' => 2});

$sth = $dbh->prepare('SELECT * FROM artist WHERE id = $1 OR parent_id = $1');
$sth->execute(2);
```

### Lists

A placeholder with `...` before it takes a list. It's written as a `?`
for each of its values, separated by commas. Use it for `IN`, and
anywhere else SQL takes a list of values:

```perl
my $rows = $dbh->selectall_arrayref(
    'SELECT * FROM artist WHERE id IN (...:ids)', ids => [1, 2, 3],
);
# SELECT * FROM artist WHERE id IN (?, ?, ?), with 1, 2 and 3
```

Any style can take a list: `...?`, `...?1`, `...:1`, `...$1`,
`...:name` or `...$name`. The list is a reference to an array of at
least one plain value. It's given as any other value is: by name, or
in order. Given to a statement whose one value is a list, a single
array reference is the list, not the values in it:

```perl
$dbh->selectall_arrayref('SELECT * FROM artist WHERE id IN (...?)', [1, 2, 3]);
$dbh->selectall_arrayref(
    'SELECT * FROM artist WHERE name = ? OR id IN (...?)',
    'Abba', [1, 2, 3],
);
```

- **It's prepared with its values.** How many values a list has
  decides the statement the DBI prepares. So a statement taking a list
  is prepared by a method given its values: `do`, the select methods,
  `iterate`, `results`, and Sugar's functions. `prepare` and
  `prepare_cached` croak:
  `Expected bind values with a statement taking a list (...:ids)`.
- **A list has at least one plain value.** An empty list croaks, as
  `IN ()` isn't SQL, so the empty case is left to you:
  `Expected at least one value in a list (...:ids)`. So does a plain
  value or `undef` in place of a list. So does a list holding a
  reference, such as `[[1, 2, 3]]` to a statement whose one value is a
  list.
- **A placeholder takes a list everywhere it's used, or nowhere.** Used
  twice, it takes its list in both places.
- **Its handle is for lists of the lengths it was prepared for.** The
  statement handle of a statement taking a list, such as an iterator's
  `sth`, can be executed again with lists of the same lengths. Given
  another length, it croaks. An iterator's
  [`reset`](#iterator-methods) prepares the statement again, on a new
  handle, when a list has a different number of values. A Sugar
  statement taking a list isn't cached, as each length makes a
  different statement.
- **Databases limit the values in a statement.** A very long list can
  fail to prepare, as the same statement would with plain DBI.

With DBD::Pg, `= ANY(?)` given an array reference, as a PostgreSQL
array, is one statement whatever the array's length. The two don't mix
up. A list placeholder's array is its list, and any other
placeholder's is a PostgreSQL array. `pg_placeholder_dollaronly`
leaves the statement to DBD::Pg, so under it no placeholder can take a
list.

### What isn't a placeholder

Placeholders are looked for only in the SQL itself. These are left
unchanged:

- anything inside a quoted string or identifier: `'10:30'`, `"a:b"`,
  `` `c?` ``;
- comments: `-- :x`, `/* $1 */`;
- PostgreSQL's dollar-quoted bodies: `$$ ... $$`, `$tag$ ... $tag$`;
- a cast, such as `x::int`;
- an identifier containing `$`, such as `v$session`.

To use a `?`, `:` or `$` that isn't a placeholder, put a backslash
before it, as DBD::Pg allows. PostgreSQL's `?`, `?|` and `?&`
operators are examples. The backslash and the character after it are
passed on unchanged, and DBD::Pg removes the backslash:

```perl
$dbh->prepare(q{SELECT * FROM doc WHERE data \? 'key' AND id = :id});
```

### Strings, by dialect

Strings are read by the rules of the handle's [dialect](#the-dialect):

- With `mysql` and `MariaDB`, a backslash escapes a character in a
  string (`'it\'s'`), `"..."` is a string, and `#` starts a comment.
  MySQL's `NO_BACKSLASH_ESCAPES` mode isn't noticed.
- With other dialects, a backslash is an ordinary character in a string
  (`'C:\'`), except in PostgreSQL's `E'...'` strings.

To read one statement as another dialect, give it `ekorn_dialect`:

```perl
$dbh->prepare($statement, {ekorn_dialect => 'mysql'});
```

### DBD::Pg's own options

DBD::Pg's placeholder options are followed, whether set on the database
handle or passed to `prepare`:

- With `pg_placeholder_dollaronly`, only `$1`-style placeholders are
  recognised. The statement is passed on as written, for DBD::Pg to
  read and bind.
- With `pg_placeholder_nocolons`, the `:1` and `:name` styles aren't
  placeholders, so array slices such as `data[:2]` are left alone.

## Preparing statements

### prepare

```perl
$sth = $dbh->prepare($statement);
$sth = $dbh->prepare($statement, \%attr);
```

Prepares a statement, with placeholders in any of the
[styles](#the-styles), and returns a `DBIx::Squirrel::st`.

The statement can be:

- a string;
- an array reference of lines, which are joined with spaces;
- a code reference returning either;
- a statement handle, whose statement is prepared again.

Blank space around the statement is removed. Comments are passed on to
the database.

Unlike the DBI's `prepare`, it **always croaks** if the statement
can't be prepared, whatever `RaiseError` is set to. The message is the
one the DBI raises under `RaiseError`, such as
`DBD::SQLite::db prepare failed: near "SELEC": syntax error`.

Most statements are strings given without attributes. Such a statement
is read for placeholders once for each database handle, which keeps
what it found. The handle keeps up to 1000 statements, and starts
again when it has that many.

A statement taking a [list](#lists) can't be prepared without its
values, so `prepare` croaks given one.

### prepare_cached

```perl
$sth = $dbh->prepare_cached($statement);
$sth = $dbh->prepare_cached($statement, \%attr);
$sth = $dbh->prepare_cached($statement, \%attr, $if_active);
```

As `prepare`, using the DBI's cache of statement handles. Its errors
name `prepare_cached`, as the DBI's do. Like `prepare`, it croaks given
a statement taking a [list](#lists).

Two statements can be rewritten the same: `SELECT :a, :b` and
`SELECT :b, :a` both become `SELECT ?, ?`. Each still has a handle of
its own, as the statement as written is part of the cache's key.
DBIx::Squirrel's own attributes are part of the key too. So a
statement prepared with `{ekorn_slice => {}}` and one prepared without
have different handles.

The DBI finishes a cached handle that's still active before handing it
out. If an iterator is part way through the handle, that would cut its
results short. So such a handle isn't handed out or finished. A new
handle is made instead, and cached in its place. The exception is
`$if_active` of 2, which asks for the cached handle, unchanged.
Otherwise, `$if_active` means what it does to the DBI. A cached handle
that's active, with no iterator, is finished, after a warning, unless
`$if_active` says otherwise.

## Binding and executing

### execute

```perl
$rv = $sth->execute;
$rv = $sth->execute(@bind_values);
$rv = $sth->execute(\@bind_values);
$rv = $sth->execute(%values);
$rv = $sth->execute(\%values);
```

Executes the statement, as the DBI's `execute` does, and returns what
it returns. Values given are bound first, as [`bind`](#bind) binds
them.

A statement with numbered or named placeholders, executed without
values, croaks unless each placeholder already has a value bound. The
value can come from [`bind`](#bind), [`bind_param`](#bind_param) or an
earlier `execute`, as the DBI keeps them. The DBI would leave the
placeholder unbound, which most drivers read as `NULL`. `do`, iterators
and the select methods check the same way:

```perl
$sth = $dbh->prepare('SELECT * FROM artist WHERE id = :id');
$sth->execute;              # croaks: Expected a value for each placeholder (none for id)
$sth->bind_param(id => 1);
$sth->execute;              # runs with id 1
```

The DBI doesn't finish a statement still active from an earlier
`execute` before executing it again. Nor does `execute`, unless the
`ekorn_finish_active` attribute is true, on the database handle or the
statement.

### bind

```perl
$sth = $sth->bind(@bind_values);
$sth = $sth->bind(\@bind_values);
$sth = $sth->bind(%values);
$sth = $sth->bind(\%values);
```

Binds values to the statement's placeholders without executing it.
Returns the statement handle, or nothing if the DBI couldn't bind a
value. How values are matched to placeholders depends on the
[style](#the-styles).

If the values don't match the placeholders, it croaks at the caller's
line:

| Placeholders | Croaks when |
|---|---|
| numbered | There aren't as many values as the highest number: `Expected 2 bind values, not 1`. |
| named | There's an odd number of values: `Expected names and values in pairs`. |
| named | A name isn't one of the statement's: `Expected a placeholder of the statement (x)`. |
| named | A name has no value: `Expected a value for each placeholder (none for id)`. |

### An array reference of values

A single array reference stands for the values in it, so
`$sth->bind([1, 2])` is `$sth->bind(1, 2)`. The same goes for
`execute`, `do` and the select methods.

There are two exceptions, each for a statement taking one value:

- To a statement whose one value is a [list](#lists), the array
  reference is the list.
- DBD::Pg binds an array reference as a PostgreSQL array. So, with
  DBD::Pg, an array reference given to a statement taking one value, such as
  `SELECT * FROM artist WHERE id = ANY(?)`, is that value, as it would
  be with the DBI. Through another driver, such as DBD::ODBC, it's
  unwrapped as usual, as the driver can't bind arrays.

### bind_param

```perl
$rv = $sth->bind_param($placeholder, $value);
$rv = $sth->bind_param($placeholder, $value, \%attr);
$rv = $sth->bind_param($placeholder, $value, $bind_type);
```

Binds one value, as the DBI's `bind_param` does, and returns what it
returns. The placeholder can be given:

- by position, for `?` placeholders, as with the DBI;
- by number, for numbered placeholders, with or without the sigil: `1`
  or `'$1'`;
- by name, for named placeholders, with or without the sigil: `'id'` or
  `':id'`;
- by position, for named placeholders too, as with the DBI.

The value is bound to every use of the placeholder in the statement.
The value for a [list](#lists) is the list. Each value in it is bound
to a position of its own.

```perl
my $sth = $dbh->prepare('SELECT :a + :a, :b');
$sth->bind_param(a => 2);
$sth->bind_param(':b', 3);
$sth->execute;    # SELECT 2 + 2, 3
```

## do

```perl
$rv = $dbh->do($statement);
$rv = $dbh->do($statement, \%attr, @bind_values);
$rv = $dbh->do($statement, undef, @bind_values);
$rv = $dbh->do($statement, @bind_values);
```

Runs a statement, and returns what the DBI's `do` returns: the number
of rows affected, `0E0` for none, or `undef` on an error without
`RaiseError`. An error names `do`, as the DBI's does:
`DBD::SQLite::db do failed: ...`.

Unlike the DBI's, the attributes may be left out. The first argument
after the statement is taken as the attributes only if it's a hash
reference or `undef`. An array reference there stands for the
[values in it](#an-array-reference-of-values). Any other reference
croaks: `Expected a reference to a HASH or ARRAY`.

```perl
$dbh->do('UPDATE artist SET name = :name WHERE id = :id', name => 'Blur', id => 2);
$dbh->do('UPDATE artist SET name = ? WHERE id = ?', ['Blur', 2]);
```

A statement with `?` placeholders, or none, goes to the driver's own
`do`, as with plain DBI. So the driver's row counts and options apply,
such as running several statements with DBD::SQLite's
`sqlite_allow_multiple_statements`. A statement with numbered or named
placeholders is prepared and executed. Some drivers, such as
DBD::SQLite, then count the rows of an `UPDATE ... RETURNING` only as
they're fetched, giving `0E0`.

Like the DBI's, `do` returns no rows, even from a `SELECT` or a
`RETURNING` clause. Use `prepare` and `execute`, an
[iterator](#iterators), or the select methods, for those.

## The select methods

```perl
@row_ary  = $dbh->selectrow_array($statement, \%attr, @bind_values);
@row_ary  = $dbh->selectrow_array($statement, @bind_values);
$ary_ref  = $dbh->selectrow_arrayref($statement, \%attr, @bind_values);
$hash_ref = $dbh->selectrow_hashref($statement, \%attr, @bind_values);
$ary_ref  = $dbh->selectall_arrayref($statement, \%attr, @bind_values);
$hash_ref = $dbh->selectall_hashref($statement, $key_field, \%attr, @bind_values);
$ary_ref  = $dbh->selectcol_arrayref($statement, \%attr, @bind_values);
```

Each works as the DBI's does. It prepares the statement as `prepare`
does, unless it's already a statement handle, and binds the values as
[`bind`](#bind) binds them. The DBI's `selectall_array` goes through
`selectall_arrayref`, so it does all this too.

As with [`do`](#do), the attributes may be left out. The first
argument after the statement, or after `selectall_hashref`'s key
field, is taken as the attributes only if it's a hash reference or
`undef`. So named values given in a hash reference, or a first value
that's `undef`, need the attributes, or `undef`, in front.

```perl
my $names = $dbh->selectcol_arrayref(
    'SELECT name FROM artist WHERE id IN ($1, $2)', 1, 2,
);
```

Unlike `prepare`, they don't croak if the statement can't be prepared.
Without `RaiseError`, each returns what the DBI's returns, `undef` or
nothing.

## Iterators

An iterator executes a statement and hands out its results one at a
time. Each row is run through a [pipeline](#pipelines) of stages.

### iterate

```perl
$it = $dbh->iterate($statement, \%attr, @bind_values, @stages);
$it = $dbh->iterate($statement, @bind_values, @stages);
$it = $sth->iterate(@bind_values, @stages);
```

On a database handle, `iterate` prepares the statement, as `prepare`
does, and returns a `DBIx::Squirrel::Iterator` over its results. As
with `do`, the attributes may be left out. On a statement handle, it
returns an iterator over that statement's results.

The bind values are in any form `execute` takes. The **stages** are at
the end of the arguments. Each is a code reference, or a pipeline,
which stands for its stages. Each row is run through them, and what
comes out is the result. With no stages, the result is the row. A
stage can name the row with a signature, or leave it out and use `$_`,
as here. See [Stages](#stages).

```perl
my $it = $dbh->iterate(
    'SELECT id, name FROM artist WHERE name LIKE :pattern',
    pattern => 'A%',
    sub { $_->[1] },
);
while (my($name) = $it->next) {
    say $name;
}
```

The statement isn't executed until the first result is asked for. It's
finished when the results run out, or when the iterator is ended early,
by a [stop](#stopping-a-pipeline) or by `single`.

Rows are fetched 100 at a time, with the DBI's `fetchall_arrayref`.
Without stages, `all` takes what's left of the batch and fetches the
rest at once. That's nearly as quick as the DBI's own
`selectall_arrayref`. With stages, each row goes through them in turn,
which costs a little for each row. So to change every row of a large
result, when nothing needs to stop early, `map` over `all` is quicker
than a stage:

```perl
my @names = map { $_->[0] } $dbh->iterate('SELECT name FROM artist')->all;
```

Use stages when the rows should come one at a time, from `next`, or
may stop early, or should go with the statement, as in
[Sugar](#a-function-for-each-database-and-statement-sugar).

### Iterator methods

| Method | What it does |
|---|---|
| `next` | Returns the next result, or an empty list when there are no more. |
| `all` | Returns the results not yet handed out. In scalar context, it returns how many there were. Without stages, it fetches the rest at once. |
| `single` | Executes the statement again, and returns its one result, or nothing if it has none. It croaks if there's more than one: `Expected one result, not more`. |
| `reset` | Executes the statement again, ready to iterate from its first row, and returns the iterator. If the statement is still active, it's finished first. A statement taking a [list](#lists) is prepared again, on a new handle, if a list has a different number of values. |
| `count` | Returns the number of results handed out so far. |
| `column_names` | Returns the names of the statement's columns, as `fetchrow_hashref` would key them, following `FetchHashKeyName`. They're read when the statement is executed, as DBD::mysql gives none once the last row is fetched. |
| `sth` | Returns the statement handle. It changes when `reset` prepares a statement taking a list again. |

A stage can return `undef` as a result. So read `next` in list
context, as above, rather than testing whether what it returns is
defined.

`reset` takes new bind values, which replace those given before. It
also takes new stages, which are added to those given when the
iterator was made. Both are kept until others are given:

```perl
my $it = $dbh->iterate('SELECT name FROM artist WHERE id > ?', 0);
my @all   = $it->all;
my @later = $it->reset(10)->all;
my @upper = $it->reset(sub ($row) { uc $row->[0] })->all;    # still id > 10
```

`single` is for statements expected to find one row:

```perl
my $count = $dbh->iterate('SELECT COUNT(*) FROM artist', sub ($row) { $row->[0] })->single;
```

### Rows as arrays or hashes

Rows are fetched as arrays, unless the `ekorn_slice` attribute says
otherwise. It's a slice as the DBI's `fetchall_arrayref` takes it: an
array reference for arrays, or a hash reference for hashes. Given to
`connect`, it's the default for each statement the handle prepares.
Given to `prepare` or `iterate`, it's for that statement.

```perl
my $it = $dbh->iterate(
    'SELECT id, name FROM artist', {ekorn_slice => {}},
    sub ($row) { "$row->{id}: $row->{name}" },
);
```

### One iterator to a statement handle

A statement handle can have only one iterator going through its
results at a time. While the first has results left, executing another
over the same handle croaks:
`Expected the statement handle's other iterator to be finished`. Read
the first to the end, or let it go out of scope, first.

## Result sets and row objects

### results

```perl
$results = $dbh->results($statement, \%attr, @bind_values, @stages);
$results = $dbh->results($statement, @bind_values, @stages);
$results = $sth->results(@bind_values, @stages);
```

As [`iterate`](#iterate), returning a `DBIx::Squirrel::Results`. That's
an iterator whose rows are objects, with a method for each column,
named in lower case. The stages see the objects. A result set has the
iterator's methods, and no others.

```perl
my $results = $dbh->results('SELECT id, Name FROM artist WHERE id <= ?', 10);
while (my($artist) = $results->next) {
    say $artist->id, ' ', $artist->name;
}

say $dbh->results('SELECT * FROM artist WHERE id = $1', 1)->single->name;
```

Rows are always fetched as arrays for a result set. The `ekorn_slice`
attribute doesn't apply.

### Row objects

Each row is an array, blessed into a class with a method for each
column. There's one class for each base class and list of column
names. It's made the first time a result set fetches rows with those
columns, and kept for the life of the program. A row needs nothing
from its result set, and can be kept after the result set has gone.

A column gets no method:

- if its name can't be a method's, such as `count(*)`;
- if the base class already has a method of that name, such as `can`,
  `isa`, `get_column`, or one of your own.

When two columns have one name, as in `SELECT a.id, b.id`, the method
is the first's. To give such a column a method, give it another name
in the statement, with `AS`:

```perl
my $row = $dbh->results(
    'SELECT COUNT(*) AS total, class AS kind, b.id AS b_id FROM ...'
)->single;
say $row->total, ' ', $row->kind, ' ', $row->b_id;
```

### get_column

```perl
$value = $row->get_column($name);
$value = $row->get_column($position);
```

Returns a column's value by its name, in any case, or by its position,
from 0. It reaches every column, including those without a method. It
croaks if the row has no such column:
`Expected a column of the row (x)`.

### Methods of your own

Row classes are subclasses of `DBIx::Squirrel::Result`. Or they're
subclasses of the class given in the `ekorn_result_class` attribute,
which must itself be a subclass of `DBIx::Squirrel::Result`. So rows
can have methods of your own:

```perl
package My::Artist {
    our @ISA = 'DBIx::Squirrel::Result';
    sub shout ($self) { return uc $self->name }
}

my $results = $dbh->results($statement, {ekorn_result_class => 'My::Artist'});
say $results->single->shout;
```

A class that isn't a subclass of `DBIx::Squirrel::Result` croaks:
`Expected ekorn_result_class to be a subclass of DBIx::Squirrel::Result (My::Other)`.

## Pipelines

A pipeline is a list of stages. A stage is a code reference, or
another pipeline, which stands for its stages. See
[A pipeline's stages](#a-pipelines-stages). Iterators and result sets
run their stages with a pipeline. You can also use one on its own,
with `DBIx::Squirrel::Pipeline`, or on a handle, with
[`pipe` and `tap`](#pipe-and-tap-on-handles). A function of your own
can take stages from its caller, as `iterate` does, and run what it
returns through them. Loading a pipeline doesn't load the DBI, so that
works in code that has nothing to do with a database.

The pipeline is [Ekorn::Pipeline](https://github.com/nukopian/Ekorn-Pipeline)'s.
It began here, and is now a distribution of its own, so that any
function can take stages from its caller. DBIx::Squirrel keeps its own
names for the modules: `DBIx::Squirrel::Pipeline`,
`DBIx::Squirrel::Stop`, `DBIx::Squirrel::Gather`, and the stages in
`DBIx::Squirrel::Stages::Flow`, `Batch` and `Taps`. They're here to
stay. Each is a subclass of Ekorn's, or exports Ekorn's functions from
a list of DBIx::Squirrel's own. So a function added to Ekorn::Pipeline
reaches DBIx::Squirrel only once it's added to that list, and
documented here. Stages that need DBIx::Squirrel, such as those in
`DBIx::Squirrel::Stages::Rows`, are its own.

The names are DBIx::Squirrel's, but the objects are Ekorn's. A stop
from `Stop()` is an `Ekorn::Pipeline::Stop`, and a stage made with
`gather` is an `Ekorn::Pipeline::Gather`. That's what `ref` and `isa`
see. It's deliberate. DBIx::Squirrel's classes inherit from Ekorn's,
never the reverse, so Ekorn::Pipeline knows nothing of DBIx::Squirrel.

Ekorn::Pipeline's [reference](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md)
describes the pipeline in full, and its
[how-to](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/HOWTO.md)
has recipes for any values. This chapter keeps to what DBIx::Squirrel's
iterators, result sets and handles do with it, and to what's
DBIx::Squirrel's own. It links there for the rest.

### Stages

A stage that's a code reference is called with one value, as its
argument and in `$_`. Write it whichever way reads best: name the
value with a signature, or leave the signature out and use `$_`.

```perl
sub ($row) { $row->[1] }    # the value, named
sub { $_->[1] }             # the same, in $_
```

`$_` is localised for each call, so your own `$_` is unchanged. A
stage returns a list:

| A stage returns | It's a | The value |
|---|---|---|
| nothing | filter | is dropped. |
| one value | map | is replaced by that value, which goes on. |
| several values | flatMap | is replaced by each, which goes through the rest of the stages on its own. |

Each value goes through every stage before the next one starts. So the
values come out in order, and a stage sees them in the order a `for`
loop would. A stage returns whatever its last statement gives. So a
stage run for its side effects should still return what the next stage
needs. [How values go through stages](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md#how-values-go-through-stages)
has the details.

```perl
use DBIx::Squirrel::Pipeline;

my $p = DBIx::Squirrel::Pipeline->new(
    sub { $_->{active} ? $_ : () },          # filter
    sub ($row) { @{ $row->{tags} } },        # flatMap
    sub { uc },                              # map
);
```

### Running a pipeline

```perl
my $p = DBIx::Squirrel::Pipeline->new(@stages);

my @results = $p->(@values);           # push: values in, a list out

my $next = $p->iterator($source);      # pull: one value per call
while (my($x) = $next->()) { ... }
```

A pipeline is an object that can be called as a code reference. Called
with values, it returns what comes out of the last stage. `iterator`
returns a closure handing out those values one per call. Its source is
called only when the values from its last call have run out. Read the
closure in list context, so an `undef` value isn't mistaken for the
end. Ekorn's reference has the details:
[new](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md#new),
with the errors it raises,
[calling a pipeline](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md#calling-a-pipeline)
and [iterator](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md#iterator).

### A pipeline's stages

```perl
my @stages = $p->stages;
```

`stages` returns a pipeline's stages, in order. A pipeline given to
`new` as a stage appears as the stages it was made of. In scalar
context, `stages` returns how many there are.

A pipeline can go wherever a stage goes: in another pipeline, or given
to `iterate`, `results`, an iterator's `reset`, `pipe`, `tap`, or a
Sugar function, for a database or a statement. Its stages run in its
place.

```perl
use DBIx::Squirrel::Stages::Flow;
use DBIx::Squirrel::Stages::Rows;

my $hits = DBIx::Squirrel::Pipeline->new(
    sub { $_->[1] >= 5000 ? $_ : () },    # 5,000 plays or more
    pluck('name'),
);

my @hits    = $dbh->iterate('SELECT name, plays FROM track', $hits)->all;
my @top_ten = $dbh->iterate('SELECT name, plays FROM track ORDER BY plays DESC',
    $hits, take(10))->all;
my $first   = DBIx::Squirrel::Pipeline->new($hits, take(1));
```

The stages run as if they were written out where the pipeline stands.
They belong to that run, so a `take` inside `$hits` limits the whole
run. Give `$hits->stages` only to a function that takes code
references alone.

Make a stage that counts or remembers with
[`gather`](#gathering-stages-with-state-and-an-end). A plain closure is
the same code reference wherever it goes, so its state is shared by
every pipeline it's in.
[A pipeline as a stage](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md#a-pipeline-as-a-stage),
in Ekorn's reference, says more.

### When a stage dies

If a stage dies, the pipeline croaks at the line that called it. It
names the stage by its position, from `#1`, and indents the stage's
message. See
[When a stage dies](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md#when-a-stage-dies),
in Ekorn's reference.

```
Pipeline stage #2 failed at script.pl line 12:
    Illegal division by zero at script.pl line 8.
```

An exception object is passed on unchanged. A stage inside a pipeline
given as a stage is named by its place in each: `#2.3` is the third
stage of the pipeline given as stage #2.

Once a stage dies, its run has ended. An iterator then returns nothing
more, whether it's a pipeline's `iterator` or one that `iterate` or
`results` returns. `next` returns an empty list on every call after,
and `all` returns nothing. No more values are taken from its source,
and no end function is called. A statement's handle is finished, so no
more rows are fetched. `reset` runs the statement again, from the
start. To pass over a value a stage can't handle, the stage catches
its own error and returns nothing for it, as
[What a stop is](#what-a-stop-is) shows.

## Stopping a pipeline

A stage can end a pipeline early and quietly by calling `Stop`:

- The rest of that stage doesn't run.
- The values already out of the pipeline are kept.
- Any values the stop carries go on through the stages after it.
- Nothing else is processed.

An iterator that's stopped finishes its statement. Stages after the
one that stopped, made with
[`gather`](#gathering-stages-with-state-and-an-end), still have their
end functions called.

```perl
use DBIx::Squirrel::Stop;
use DBIx::Squirrel::Context qw(result_number);

my @first_ten = $dbh->iterate(
    'SELECT name FROM artist ORDER BY name',
    sub ($row) { Stop() if result_number() > 10; $row->[0] },
)->all;

# Stop, passing on a last value
my $found = $dbh->iterate(
    $statement,
    sub ($row) { $row->[0] == $wanted ? Stop($row) : () },
)->single;
```

`Stop` is exported by default. `DBIx::Squirrel::Stop->throw(@values)`
does the same without importing it. To keep `Stop` out of your
namespace:

```perl
use DBIx::Squirrel::Stop ();
```

### What a stop is

A stop is an exception. `DBIx::Squirrel::Stop` is a subclass of
`Ekorn::Pipeline::Stop`, and `Stop()` is Ekorn's. So every stop is an
`Ekorn::Pipeline::Stop`, though not every one is a
`DBIx::Squirrel::Stop`. Ekorn's reference says what a stop holds, in
[The stop object](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md#the-stop-object).
It also says how a subclass of your own stops a pipeline, in
[Subclasses](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md#subclasses).

A stage that catches errors itself, with `eval` or `try`, should throw
a stop on again. Check for `Ekorn::Pipeline::Stop`. Every stop is one,
including those the canned stages throw, such as `take`'s. Checking
for `DBIx::Squirrel::Stop` would miss them:

```perl
sub ($row) {
    try { ... }
    catch ($e) {
        die $e if $e isa 'Ekorn::Pipeline::Stop';
        ...
    }
}
```

## Gathering: stages with state, and an end

A stage can't tell when the last value has gone by. And whatever a
closure keeps stays there from one run of the pipeline to the next.
`gather` makes a stage that has both: state of its own on each run,
and an end function, called once the values run out.

```perl
use DBIx::Squirrel::Gather;

# Rows in batches of $size, the last, shorter one at the end
sub batches_of ($size) {
    return gather {
        my @batch;    # this run's
        my $stage = sub ($row) {
            push @batch, $row;
            return @batch == $size ? [splice @batch] : ();
        };
        my $end = sub () { @batch ? [@batch] : () };
        return ($stage, $end);
    };
}

my $batches = $dbh->iterate('SELECT id, name FROM track', batches_of(500));
while (my($batch) = $batches->next) { ... }
```

`batch`, one of the [canned stages](#canned-stages), does this
already. It's written out here to show how.

The block given to `gather` is called at the start of each run, so
whatever it declares is fresh each time. A run is each execution of an
iterator or result set, including after `reset`, each call of a Sugar
statement, and each call of a pipeline. The block returns the stage,
which is called with each value as any stage is, and optionally an end
function. Make any stage that keeps state, even a count, with
`gather`, so that it starts afresh.

The end function is called once the values run out, even when there
were none. What it returns goes through the rest of the stages, as
what a stage returns does. After a [stop](#stopping-a-pipeline), only
the ends of the stages after the one that stopped are called. Ekorn's
reference gives the order the ends are called in, in
[End functions](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md#end-functions).
It also says what the block must return, in
[gather](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md#gather).

The stage the block returns can be a pipeline. Its stages are made for
the run in its place, so the block can build a pipeline for each run,
or choose one. The block's end function, if any, is called after the
ends of the pipeline's stages.

```perl
my $two = $dbh->iterate(
    'SELECT name FROM artist ORDER BY name',
    gather {
        my $n = 0;    # this run's
        DBIx::Squirrel::Pipeline->new(sub { ++$n . ". $_->[0]" }, take(2));
    },
);
```

A stage made with `gather` is an `Ekorn::Pipeline::Gather`, which is a
code reference, so it can be given wherever a stage can. `gather` is
exported by default. To keep it out of your namespace:

```perl
use DBIx::Squirrel::Gather ();
```

## What a stage can ask: Context

Inside a stage run by an iterator or result set, these functions tell
the stage about the result it's making: things it can't work out from
the value it's given. Outside a stage, they return `undef`. None is
exported by default.

```perl
use DBIx::Squirrel::Context qw(iterator result_number result_original);

my $it = $dbh->iterate(
    'SELECT name FROM artist ORDER BY name',
    sub ($row) { "@{[ result_number ]}. $row->[0]" },
);
```

| Function | Returns |
|---|---|
| `iterator` | The iterator running the stage. Its `sth` is the statement handle, and the statement handle's `Database` is the database handle. |
| `result_number` | The number of the result being made, from 1. It counts results, not rows. While a stage drops rows, the number stays the same. Each value a stage returns in place of one row is a result of its own. In an end function, it's the number of the first value the end returns. |
| `result_original` | The row the result is being made from, as it was fetched, before any stage changed it. For a result set, it's the row object. In an [end function](#gathering-stages-with-state-and-an-end), and the stages after it, it's `undef`. What an end gives comes from every row, not one. |

## pipe and tap on handles

Database and statement handles both have these methods. The examples
use a database handle. On a statement handle, the statement handle
goes through the stages instead. The methods are
Ekorn::Pipeline::Pipes's.
[pipe and tap](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md#pipe-and-tap-ekornpipelinepipes),
in Ekorn's reference, describes them, and how to give a class of your
own the same.

### pipe

```perl
@results = $dbh->pipe(@stages);
$result  = $dbh->pipe(@stages);
```

Runs the handle through a pipeline of stages, and returns what comes
out of the last one. In list context, that's all of it. In scalar
context, it's the first value, or `undef` if there's none. To count
the values instead:

```perl
my $count = () = $dbh->pipe(@stages);
```

With no stages, `pipe` returns the handle. A stage can end the pipeline
early with `Stop`.

```perl
my @odd_doubled = $dbh->pipe(
    sub ($dbh) { (3, 4, 5) },
    sub { $_ % 2 ? $_ : () },
    sub { $_ * 2 },
);    # (6, 10)
```

### tap

```perl
$dbh = $dbh->tap(@stages);
```

Runs the handle through a pipeline of stages, as a branch off to the
side, for their side effects. It returns the handle, so a chain of
method calls can carry on after it. What comes out of the last stage
is dropped. `tap` returns the handle however the stages end.

```perl
$dbh->tap(
    sub ($dbh)   { $dbh->selectrow_array('SELECT COUNT(*) FROM artist') },
    sub ($count) { log_count($count) },
)->do('DELETE FROM artist WHERE id = ?', undef, $id);
```

## Canned stages

Four modules of ready-made stages ship with DBIx::Squirrel, each for
one kind of job. Each exports the stages it's usually used for, and
the rest on request. `:all` gives them all, and `()` none. Naming a
stage in the import list replaces the defaults. To have the defaults
and one more, name `:DEFAULT` too:

```perl
use DBIx::Squirrel::Stages::Flow qw(:DEFAULT take_while);
```

| Module | Exported by default | On request |
|---|---|---|
| `DBIx::Squirrel::Stages::Flow` | `take($n)`, `drop($n)` | `take_while { ... }`, `drop_while { ... }` |
| `DBIx::Squirrel::Stages::Rows` | `pluck($column)`, `as_hash` | |
| `DBIx::Squirrel::Stages::Batch` | `batch($n)`, `collect`, `collect { ... }` | |
| `DBIx::Squirrel::Stages::Taps` | `peek { ... }`, `count_into(\$n)` | `dump_to($fh)` |

What each stage does:

| Stage | What it does |
|---|---|
| `take($n)` | Passes on the first `$n` values, then stops the pipeline, so no more rows are fetched. |
| `drop($n)` | Drops the first `$n` values, and passes on the rest. |
| `take_while { ... }` | Passes on values while the block is true of them. At the first it's false of, it stops the pipeline, and doesn't pass that value on. |
| `drop_while { ... }` | Drops values while the block is true of them, then passes on the rest, from the first it's false of. |
| `pluck($column)` | Gives one column of each row, by its name, in any case, or its position, from 0, whether the row is an array, a hash or a row object. |
| `as_hash` | Gives each row as a hash, as `fetchrow_hashref` would, keyed as `FetchHashKeyName` says. A hash row is passed on unchanged. |
| `batch($n)` | Passes values on in batches of `$n`, each an array. The last, shorter batch comes when the values run out. |
| `collect` | Holds every value. When they run out, it passes on an array of them. |
| `collect { ... }` | Holds every value. When they run out, it passes on what the block makes of them, given as its arguments. |
| `peek { ... }` | Calls the block with each value, and passes the value on. |
| `count_into(\$n)` | Counts the values into `$n`, from 0 on each run, and passes them on. |
| `dump_to($fh)` | Writes each value, with Data::Dumper, to `$fh` or STDERR, and passes it on. For debugging: see below. |

`dump_to` is for debugging. It writes each value in full, secrets and
all. It doesn't escape control characters in strings, so a value from
outside can send escape sequences to a terminal.

Flow's, Batch's and Taps' stages are Ekorn::Pipeline's. Its
reference's
[Canned stages](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md#canned-stages)
describes them in full. Rows' stages are DBIx::Squirrel's own.

Each is a function that makes a stage. It checks what it's given when
it's called, not on each value. Those that keep a count or hold values
are made with [`gather`](#gathering-stages-with-state-and-an-end), so
they start afresh on each run. `pluck` and `as_hash` find the column
names through the iterator running them. So a name for an array row,
or `as_hash`, needs the stages to be run by an iterator or result set.

```perl
use DBIx::Squirrel::Stages::Flow;     # take, drop
use DBIx::Squirrel::Stages::Rows;     # pluck, as_hash
use DBIx::Squirrel::Stages::Batch;    # batch, collect
use DBIx::Squirrel::Stages::Taps;     # peek, count_into

# The second page of ten, as hashes, counting the rows read
my $read = 0;
my @page = $dbh->iterate(
    'SELECT id, name FROM artist ORDER BY name',
    count_into(\$read),
    drop(10), take(10),
    as_hash,
)->all;

# Names, 500 at a time, saying how many in each batch
my $batches = $dbh->iterate(
    'SELECT name FROM track',
    pluck('name'), batch(500),
    peek { warn scalar(@$_), " names\n" },
);

# The first three names, from a handle
my @three = $dbh->pipe(
    sub ($dbh) { @{ $dbh->selectcol_arrayref('SELECT name FROM artist ORDER BY name') } },
    take(3),
);
```

In SQL, `LIMIT` and `OFFSET` page results in the database. `take` and
`drop` are for when a stage in Perl decides which rows go on, or for
values from `pipe`.

## Writing stages

A stage of your own is a code reference, or a pipeline of other
stages. Ekorn's reference, in
[Writing stages](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md#writing-stages),
and its how-to, in
[Writing stages for others](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/HOWTO.md#writing-stages-for-others),
say how to write one that works alongside the canned stages:

- a function that makes it, checking its options once;
- state in a `gather` block, so it starts afresh on each run, as after
  `reset` or on each call of a Sugar statement;
- an end, for a stage that holds values;
- `Stop`, for one that knows no more are wanted;
- a tap that returns the value it was given;
- names, exports and tests.

What follows is what's particular to stages for rows.

**The shapes of a row.** A row can be an array, a hash (with the
`ekorn_slice` attribute), or a row object (from `results`). A stage
for others should say which it takes, or take all three, as `pluck`
does. [Context](#what-a-stage-can-ask-context) gives the iterator
running the stage, whose `column_names` are the statement's columns.
It also gives `result_original`, the row as fetched.

**Errors.** A function that makes a stage croaks when it's given the
wrong things, so the message names the line that called it. A module
of stages sets its `@CARP_NOT` to DBIx::Squirrel's internal packages,
which take in the DBI's and Ekorn::Pipeline's. Then what it croaks
while a row goes through its stage is reported at the line that asked
for the result, not inside DBIx::Squirrel:

```perl
use DBIx::Squirrel::Errors qw(croakf);

our @CARP_NOT = @DBIx::Squirrel::Errors::INTERNAL;
```

`croakf` croaks with a message made by `sprintf`. Its format is a
literal, written in the code, with the values as its arguments. Never
make the format from data: it does whatever its `%` directives say.

**Where they go.** A stage goes where what it needs to know is. One
that needs a database, a statement, a row's column names, or the row a
result came from goes under `DBIx::Squirrel::Stages::`. One that would
work on values from anywhere belongs under `Ekorn::Pipeline::Stages::`,
where any function's stages can use it, even if it was written for
rows. Ekorn::Pipeline can't depend on DBIx::Squirrel, so a stage that
would `use` DBIx::Squirrel goes under `DBIx::Squirrel::Stages::`. A
stage added under `Ekorn::Pipeline::Stages::` reaches DBIx::Squirrel's
users only once DBIx::Squirrel adds it to the names its own modules of
stages export. The how-to's
[Decide where a stage belongs](HOWTO.md#decide-where-a-stage-belongs)
says how to choose.

**Testing.** A pipeline called with values tests a stage without a
database. Run it twice, to show it starts afresh. Then run it on rows
from an in-memory SQLite database, in each shape it takes:

```perl
use Test2::V0;
use DBIx::Squirrel::Gather;
use DBIx::Squirrel::Pipeline;

# Each value, numbered from 1 on each run
sub numbered () {
    return gather {
        my $n = 0;
        return sub ($value) { [++$n, $value] };
    };
}

my $p = DBIx::Squirrel::Pipeline->new(numbered);
is [$p->(qw(a b))], [[1, 'a'], [2, 'b']], 'numbered';
is [$p->(qw(c))],   [[1, 'c']],           'from 1 on each run';
```

**Publishing.** Name a module of stages for its job, as
`DBIx::Squirrel::Stages::JSON`, in a distribution named
`DBIx-Squirrel-Stages-JSON`. Have it require DBIx::Squirrel v2.0.3 or
later, the first on Ekorn::Pipeline.

## A function for each database and statement: Sugar

`DBIx::Squirrel::Sugar` gives each database a name. The package that
names it gets a function of that name, which returns the database
handle or runs a statement on it. A statement gets a function too,
which runs it with the bind values and any stages given.

### Defining them on use

```perl
use DBIx::Squirrel::Sugar database => {
    music => [$ENV{MUSIC_DSN}, $ENV{MUSIC_USER}, $ENV{MUSIC_PASS}],
};

use DBIx::Squirrel::Sugar statement => {
    artist_names => [music => 'SELECT name FROM artist', sub ($row) { $row->[0] }],
    artist       => [music => 'SELECT * FROM artist WHERE id = :id'],
};
```

Given a hash reference after `database` or `statement`, `use` defines
each database or statement named in it, with its arguments in an array
reference. It gives the package each function while the package is
compiled, so the function can be called without parentheses.

The arguments are worked out then too. The environment, literals, and
what a `BEGIN` block has set are there, but a variable the program
sets as it runs is not yet.

`use` also gives the package the `database` and `statement` functions.
To have just those:

```perl
use DBIx::Squirrel::Sugar qw(database statement);
```

### database

```perl
$dbh      = database($name);
$function = database($name, @connect_args);
```

Given a name, returns the handle of the database defined by that name,
anywhere in the program. It connects to the database if it isn't
connected.

Given a name and the arguments `connect` takes, it defines a database
by that name. It gives the calling package a function of that name,
and returns the function. A database defined with a database handle,
in place of a data source, is a clone of it, as `connect` makes. The
clone is made when the database is first used.

A database is defined once in a program, by a name that can be a
function's. The package can't have a function of that name already.

### The function a database is given

```perl
$dbh     = music();
$sth     = music($statement, @bind_values);
$sth     = music($statement, \%attr, @bind_values);
@results = music($statement, @bind_values, @stages);
$count   = music($statement, @bind_values, @stages);
```

| Called with | It |
|---|---|
| nothing | returns the database handle. |
| a statement and bind values | prepares the statement, executes it, and returns the statement handle, or nothing if it couldn't be executed. |
| those, and stages at the end | iterates over the results, as `iterate` does, and returns them all, or, in scalar context, how many there were. |

A hash reference or `undef` straight after the statement is the
attributes to prepare it with. The statement can be a statement
handle, which is itself executed, or iterated over.

```perl
my $sth   = music 'SELECT * FROM artist WHERE id = ?', 1;
my @names = music 'SELECT name FROM artist', sub ($row) { $row->[0] };
```

### statement

```perl
$function = statement($name, $database, $statement, @stages);
$function = statement($name, $database, $statement, \%attr, @stages);
```

Defines a statement by that name, on the database of that name. The
attributes are those to prepare it with, and the stages are its own.
It gives the calling package a function of that name, and returns the
function. The database is found when the function runs, so it can be
defined after the statement.

### The function a statement is given

```perl
$sth     = artist(@bind_values);
@results = artist(@bind_values, @stages);
$count   = artist(@bind_values, @stages);
```

It executes the statement with the bind values, and returns the
statement handle, or nothing if it couldn't be executed.

With stages, its own or those given after the bind values, it iterates
over the results. They go through its own stages, then those given. It
returns them all, or, in scalar context, how many there were. Stages
given are for that call only.

```perl
my @all   = artist_names;                             # through its stage
my @upper = artist_names sub ($name) { uc $name };    # and one more
my $found = artist id => 1;                           # the statement handle
```

The statement is prepared once for each database handle, with
`prepare_cached`. Its handle may be in use: by a statement handle not
read to the end, or by a stage calling the same function. A call then
prepares one of its own. A statement taking a [list](#lists) is
prepared for each call's values instead, and isn't cached.

### Connections

A database is connected to when it's first used, not when it's
defined, with `connect_cached`. So two databases defined with the same
arguments share a handle.

The handle is kept, and each use has the same one, without a ping to
the database each time. It's pinged only while its last call has
failed, which leaves the error to be read. It's made again if the
connection has gone, or if the handle has been disconnected. So the
call after a connection drops fails, as it would with plain DBI, and
the call after that has a new connection.

## Errors

Errors are reported at the line of your code that called
DBIx::Squirrel, never at a line inside it or the DBI. That includes the
DBI's own errors under `RaiseError`, such as
`DBD::SQLite::db prepare failed: near "SELEC": syntax error`, which
keep the DBI's message.

DBIx::Squirrel croaks where the DBI would return `undef` in `connect`,
`prepare` and `prepare_cached`. The error then has the message the DBI
raises under `RaiseError`, so it reads the same whatever `RaiseError`
is set to.

Each error names the method you called, as plain DBI does: `do` and the
select methods, not the `prepare` or `execute` they call.

An error from a `HandleError` callback, or one that isn't a string, is
passed on unchanged.

The DBI gives warnings under `PrintError`, its default. They're
reported the same way plain DBI reports them: at your line, naming the
method you called.

## Diagnostics

These are DBIx::Squirrel's own messages. Each is reported at the
caller's line. Those starting "Expected" say what was expected.

### Connecting, preparing and binding

| Message | Cause |
|---|---|
| `Expected a statement` | The statement was blank, or a reference other than those `prepare` takes. |
| `Expected one placeholder style, not several (%s)` | The statement mixed styles, such as `?` and `:name`. Each is listed as an example. |
| `Expected placeholders numbered from 1 (%s)` | A numbered placeholder such as `$0`. |
| `Expected ekorn_slice to be a reference to an ARRAY or HASH` | `ekorn_slice` was something else. |
| `Expected a reference to a HASH or ARRAY` | The first argument after the statement in `do`, `iterate`, `results` or a select method was a reference, but not to a hash or an array. |
| `Expected %d bind values, not %d` | A statement with numbered placeholders was given more or fewer values than its highest number. |
| `Expected names and values in pairs` | A statement with named placeholders was given an odd number of values. |
| `Expected a placeholder of the statement (%s)` | A value was given for a placeholder the statement doesn't have. |
| `Expected a value for each placeholder (none for %s)` | A statement with named placeholders wasn't given a value for each name, or a statement with numbered or named placeholders was executed without values when some had none bound. |
| `Expected bind values with a statement taking a list (%s)` | `prepare` or `prepare_cached` was given a statement taking a [list](#lists). Each list placeholder is named, and a `?` is named by its position: `...? at 2`. |
| `Expected a placeholder to take a list everywhere or nowhere (%s)` | A placeholder was used with `...` in one place and without it in another. |
| `Expected no list placeholder with pg_placeholder_dollaronly (%s)` | A `$1` placeholder took a list under DBD::Pg's `pg_placeholder_dollaronly`. |
| `Expected a reference to an ARRAY for a list (%s)` | A list placeholder was given a plain value, `undef`, or a reference to something other than an array. |
| `Expected at least one value in a list (%s)` | A list placeholder was given an empty list. |
| `Expected plain values in a list (%s)` | A list held a reference, as `[[1, 2]]` does to a statement whose one value is a list. |
| `Expected %d values in a list, as prepared, not %d (%s)` | The handle of a statement taking a list was executed or bound with a list of another length. |

### Iterators and result sets

| Message | Cause |
|---|---|
| `Expected a statement handle` | `DBIx::Squirrel::Iterator->new` wasn't given a `DBIx::Squirrel::st`. |
| `Expected one result, not more` | `single` found a second result. |
| `Expected the statement handle's other iterator to be finished` | Another iterator over the same statement handle has results left. |
| `Expected ekorn_result_class to be a subclass of DBIx::Squirrel::Result (%s)` | `ekorn_result_class` named a class that isn't one. |
| `Expected a column of the row (%s)` | `get_column` was given a name or position the row doesn't have. |

### Pipelines

| Message | Cause |
|---|---|
| `Expected stage #%d to be a code reference or a pipeline` | Something passed as a stage wasn't a code reference or a pipeline. No stage runs. |
| `Expected a code reference` | The source given to a pipeline's `iterator`, or the block given to `gather`, wasn't a code reference. |
| `Expected stage #%s, made with gather, to return a code reference or a pipeline, and optionally an end function` | The block given to `gather` for that stage returned something else. |
| `Pipeline stage #%s failed at %s line %d:` | A stage, or its end function, died. The message it died with follows, indented. A stage inside a pipeline given as a stage is named `#2.3`, for the third stage of the pipeline given as stage #2. |
| `Stop used outside a pipeline` | `Stop` was called where no pipeline was running to catch it. |

### Canned stages

| Message | Cause |
|---|---|
| `Expected a count of 0 or more` | `take` or `drop` was given something other than a whole number. |
| `Expected a batch size of 1 or more` | `batch` was given something other than a whole number above 0. |
| `Expected a code reference` | `take_while`, `drop_while`, `collect` or `peek` was given something other than a block or code reference. |
| `Expected a column, by name or position` | `pluck` was given no column, or an empty name. |
| `Expected a column of the row (%s)` | A row hasn't got the column `pluck` was given. |
| `Expected an iterator, for the column names` | `as_hash`, or `pluck` with a name for an array row or a position for a hash row, ran where no iterator was running it. |
| `Expected a row: an array, a hash or a row object` | `pluck` or `as_hash` was given a value that isn't a row. |
| `Expected a reference to a scalar` | `count_into` was given something else. |
| `Expected an open filehandle` | `dump_to` was given something else. |

### Sugar

| Message | Cause |
|---|---|
| `Expected database or statement, not %s` | `use DBIx::Squirrel::Sugar` was given something else. |
| `Expected the arguments to connect to %s in an ARRAY` | A database's definition, given to `use`, wasn't an array reference. |
| `Expected the statement %s in an ARRAY` | A statement's definition, given to `use`, wasn't an array reference. |
| `Expected a name for a database (%s)` | The name can't be a function's. |
| `Expected a name for a statement (%s)` | The name can't be a function's. |
| `Expected a database defined once (%s)` | The name was given to another database already. |
| `Expected a database defined as %s` | `database` was given a name no database has. |
| `Expected a database and a statement for %s` | A statement's definition didn't name its database, or have its SQL. |
| `Expected only code references or pipelines after the statement for %s` | A statement's definition had something other than stages, which are code references or pipelines, after the statement and its attributes. |
| `Expected no function of the name in %s already (%s)` | The package has a function of that name already. |

## Differences from plain DBI

Where DBIx::Squirrel and plain DBI do the same thing, they give the same
result. These are the places they differ.

| | Plain DBI | DBIx::Squirrel |
|---|---|---|
| Placeholders | `?`, and whatever the driver adds. | `?`, `?1`, `:1`, `$1`, `:name` and `$name`, rewritten as `?` for the DBI. |
| Numbered and named placeholders | Bound by position. | Bound once, by number or name, wherever they appear. |
| Lists, as for `IN` | A `?` for each value, written out. | `...?`, `...$1` or `...:name`, written as a `?` for each value of the list given. |
| `connect` failing | Returns `undef`, unless `RaiseError`. | Always croaks, with the DBI's `RaiseError` message. |
| `prepare` failing | Returns `undef`, unless `RaiseError`. | Always croaks, with the DBI's `RaiseError` message. |
| Attributes in `do` and the select methods | Required, or `undef`, before the bind values. | May be left out. |
| A lone array reference of bind values | A value. | The values in it, except for a statement taking one value that's a list, or with DBD::Pg. |
| Where errors and warnings are reported | The line inside the module that called the DBI. | The line of your code that called DBIx::Squirrel. |
| Statements | A string. | A string, lines in an array reference, a code reference returning either, or a statement handle. |
| Executing an active statement | Left to the driver. | The same, or finished first with `ekorn_finish_active`. |
| Executing with placeholders unbound | Left to the driver, which most read as `NULL`. | Croaks, for numbered and named placeholders: `Expected a value for each placeholder (none for id)`. |
| Iterators, result sets, pipelines | None. | `iterate`, `results`, `pipe`, `tap` and Sugar. |

## Upgrading from 1.x

DBIx::Squirrel 2.0 is a rewrite, not an update. Code written for 1.x
needs changes before it runs on 2.0. The ideas carry over, so most
changes are a rename or a simpler call. But some methods keep their
names and change what they do. They're marked **in bold** below.

To stay on 1.x, which supports Perl 5.10.1 and later, install the last
version by its number:

```
cpanm DBIx::Squirrel@1.6.5
```

### Requirements and loading

| 1.x | 2.0 |
|---|---|
| Perl 5.10.1 or later. | Perl 5.36 or later. |
| Hard dependencies on Compress::Bzip2, Crypt::CBC, Dotenv, JSON::Syck, YAML::Syck and others. | DBI, Ekorn::Pipeline, Ref::Util, namespace::clean, and a few core modules. |
| Loading it read a `.env` file in the current directory, through Dotenv. | Nothing is read. Load your environment yourself. |

### Importing and the entity helpers

| 1.x | 2.0 |
|---|---|
| `use DBIx::Squirrel database_entities => [qw(db artists)];` | `use DBIx::Squirrel::Sugar database => {...}, statement => {...};` |
| A helper was associated at run time: `db(DBIx::Squirrel->connect(...))`. | A database is defined by the arguments to connect with, and connected when first used: `database => {db => [$dsn, $user, $pass]}`. |
| A helper could hold a database, a statement or an iterator. | A function holds a database, or a statement on a database by name, with stages of its own. |
| A helper for a result set returned the iterator, so `artist('Aerosmith')->single->ArtistId`. | A statement's function returns the statement handle, or, with stages, the results themselves, as arrays: `artist('Aerosmith', sub ($row) { $row->[0] })`. |

```perl
# 1.x
use DBIx::Squirrel database_entities => [qw(db artist)];
db(DBIx::Squirrel->connect($dsn, $user, $pass));
artist(db->results('SELECT * FROM artists WHERE Name = ? LIMIT 1'));
say artist('Aerosmith')->single->ArtistId;

# 2.0
use DBIx::Squirrel::Sugar
    database  => {db => [$ENV{DSN}, $ENV{USER}, $ENV{PASS}]},
    statement => {artist_id => [db => 'SELECT ArtistId FROM artists WHERE Name = ?', sub ($row) { $row->[0] }]};
my($id) = artist_id('Aerosmith');
```

See [A function for each database and statement: Sugar](#a-function-for-each-database-and-statement-sugar).

### Placeholders and binding

| 1.x | 2.0 |
|---|---|
| `?`, `?1`, `:1`, `$1` and `:name`. | The same, and `$name`. |
| Placeholders were found anywhere in the statement: in quoted strings, and in casts, so `x::int` broke. | Not in quoted strings, comments, casts or PostgreSQL's dollar-quoted bodies, read by the database's rules. See [What isn't a placeholder](#what-isnt-a-placeholder). |
| Styles could be mixed. | One style to a statement. A mix croaks. |
| `--` comments were removed before the statement reached the database. | Comments are passed on to the database. |

Binding by name, as pairs or in a hash reference, with or without the
sigil, works as it did.

### do

| 1.x | 2.0 |
|---|---|
| **In list context, `do` returned the row count and the statement handle.** | `do` returns what the DBI's returns, in any context. Use `prepare` and `execute` for the handle. |

### Iterator and result set methods

| 1.x | 2.0 |
|---|---|
| `it` and `iterator`, aliases of `iterate`. | `iterate` only. |
| `rs` and `resultset`, aliases of `results`. | `results` only. |
| `$dbh->iterate($sql, [@bind_values, @transforms])`: values and stages in one array reference. | Stages are at the end of the arguments, as code references or pipelines: `$dbh->iterate($sql, @bind_values, @stages)`. |
| **`next` put the result in `$_`**, as in `while ($it->next) { say $_->Name }`. | Nothing is put in `$_`: `while (my($row) = $it->next) { say $row->name }`. |
| **`all` in scalar context returned a reference to the results.** | `all` in scalar context returns how many there were: `my $results = [$it->all]`. |
| **`count` fetched the rest of the results and returned how many there were in all.** | `count` returns how many have been handed out so far, as 1.x's `count_fetched` did. To count them all: `my $n = $it->all`. |
| `count_fetched`. | `count`. |
| **`single` and `one` returned the first result, with a warning if there were more.** | `single` executes the statement again and returns its one result, croaking if there's more than one. `one` is gone. |
| `first`, `last` and `last_fetched`. | Gone: `single`, `next`, or a stage. |
| `remaining`. | `all`, which returns the results not yet handed out. |
| `start` and `iterate` on an iterator, to execute it with new bind values. | `reset(@bind_values, @stages)`. |
| `reset($slice, $cache_size)`, to change the slice or the cache size. | `reset` takes bind values and stages. The slice is the `ekorn_slice` attribute. Rows are fetched 100 at a time. |
| `slice`, `cache_size` and their package-wide defaults, `$DBIx::Squirrel::it::DEFAULT_SLICE` among them. | The `ekorn_slice` attribute, on `connect` or `prepare`. |
| `is_active`, `not_active` and `rows`. | Gone: `$it->sth->{Active}` and `$it->sth->rows`. |

### Rows as objects

| 1.x | 2.0 |
|---|---|
| **A column's method matched its name in any case:** `$row->ArtistId` or `$row->artistid`. | Methods are named in lower case only: `$row->artistid`. |
| Methods were made the first time each was called. | A class with a method for each column is made for each list of columns. See [Row objects](#row-objects). |
| A column whose name can't be a method's, such as `COUNT(*)`, was reached by its position. | By its position still, as rows are arrays, or with `get_column`, or given a name with `AS`. |

### Transformations, now stages

The stages work as transformations did. Each gets a value as its
argument and in `$_`, and returns nothing to drop it, one value, or
several. These have changed:

| 1.x | 2.0 |
|---|---|
| `use DBIx::Squirrel::it qw(...)`, for what a stage can ask. | `use DBIx::Squirrel::Context qw(...)`. |
| `iterator`, `result_number` and `result_original`. | The same, from DBIx::Squirrel::Context. |
| `database` and `statement`. | `iterator->sth->{Database}` and `iterator->sth`. |
| `result` and `result_current`. | The stage's argument. |
| `result_first`, `result_prev`, `result_previous` and `result_offset`. | Gone. A stage that needs them keeps them itself, in a [`gather`](#gathering-stages-with-state-and-an-end) block. |
| `DBIx::Squirrel::Transform::Data::Dumper`'s `as_perl`, and `DBIx::Squirrel::Transform::IO`'s `stdout` and `stderr`. | `dump_to` and `peek`, from DBIx::Squirrel::Stages::Taps. See [Canned stages](#canned-stages). |
| No way to end a transformation early. | `Stop`, from DBIx::Squirrel::Stop. See [Stopping a pipeline](#stopping-a-pipeline). |

### Gone, out of scope

These have no place in 2.0. Any that come back will come back as
distributions of their own.

| 1.x | Instead |
|---|---|
| `DBIx::Squirrel::Crypt::Fernet`, and `decrypt` from DBIx::Squirrel::util. | A Fernet module from CPAN. |
| `DBIx::Squirrel::Transform::JSON::Syck` and `DBIx::Squirrel::Transform::YAML::Syck`. | A stage of your own calling a JSON or YAML module. See [Writing stages](#writing-stages). |
| `get_file_contents`, `slurp`, `uncompress`, `unmarshal` and `utf8decode`, from DBIx::Squirrel::util. | Path::Tiny, IO::Uncompress::Bunzip2, a JSON module, and Encode. |
| `load_tuples`, on a database handle. | `prepare` and `execute`, in a loop. |
| `statement_digest`, `statement_normalise`, `statement_study` and `statement_trim`, on a statement handle. | `study_sql` and `trim_sql`, from DBIx::Squirrel::Placeholders. |

## The modules

| Module | What it is |
|---|---|
| `DBIx::Squirrel` | The class you connect with; a subclass of `DBI`. |
| `DBIx::Squirrel::db` | The database handle class; a subclass of `DBI::db`. |
| `DBIx::Squirrel::st` | The statement handle class; a subclass of `DBI::st`. |
| `DBIx::Squirrel::Iterator` | An iterator over a statement's results. |
| `DBIx::Squirrel::Results` | An iterator handing out rows as objects. |
| `DBIx::Squirrel::Result` | The base class of row objects. |
| `DBIx::Squirrel::Pipeline` | Runs values through a list of stages. |
| `DBIx::Squirrel::Pipes` | The `pipe` and `tap` methods of both handle classes. |
| `DBIx::Squirrel::Stop` | Ends a pipeline early. |
| `DBIx::Squirrel::Gather` | Makes a stage afresh for each run, with a function called at the end. |
| `DBIx::Squirrel::Stages::Flow` | Canned stages taking or dropping values: `take`, `drop`, `take_while`, `drop_while`. |
| `DBIx::Squirrel::Stages::Rows` | Canned stages reshaping rows: `pluck`, `as_hash`. |
| `DBIx::Squirrel::Stages::Batch` | Canned stages gathering values: `batch`, `collect`. |
| `DBIx::Squirrel::Stages::Taps` | Canned stages run for their side effects: `peek`, `count_into`, `dump_to`. |
| `DBIx::Squirrel::Context` | What a stage can ask about the result it's making. |
| `DBIx::Squirrel::Sugar` | A function for each database and statement. |
| `DBIx::Squirrel::Placeholders` | Finds the placeholders in a statement, and matches values to them. |
| `DBIx::Squirrel::Errors` | Reports errors at the caller's line. Internal, apart from `croakf` and `@INTERNAL`, which a module of stages uses. See [Writing stages](#writing-stages). |
| `DBIx::Squirrel::Util` | Helpers the modules share. Internal. |

`DBIx::Squirrel::Pipeline`, `Pipes`, `Stop` and `Gather`, and the
stages in `DBIx::Squirrel::Stages::Flow`, `Batch` and `Taps`, are
DBIx::Squirrel's names for [Ekorn::Pipeline](#pipelines)'s modules.
