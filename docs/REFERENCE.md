# DBIx::Squirrel reference

DBI, minus the boilerplate, plus a pipeline.

DBIx::Squirrel keeps you writing SQL, as the DBI does, and takes away the
friction around it: placeholders in whatever style you like, iterators
over results, rows as objects, and a pipeline of transformations
declared beside the query. It subclasses the DBI, so everything the DBI
does still works, and where the two do the same thing, they give the
same result.

This reference describes every feature, with examples. Each module's own
POD says the same things more briefly, and is the authority where the
two differ.

**In development.** This is the successor to DBIx-Squirrel 1.x, being
rewritten for Perl 5.36 or later, and isn't released yet.

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
- [What a stage can ask: Context](#what-a-stage-can-ask-context)
- [pipe and tap on handles](#pipe-and-tap-on-handles)
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

# Placeholders in the style you like: ?, ?1, :1, $1 or :name
my $sth = $dbh->prepare('SELECT * FROM artist WHERE id = :id OR name = :name');
$sth->execute(id => 1, name => 'AC/DC');

# A numbered placeholder takes one value, wherever it appears
my $row = $dbh->selectrow_hashref(
    'SELECT * FROM artist WHERE id = $1 OR parent_id = $1', undef, 2,
);

# An iterator over the results, each run through a pipeline of stages
my $names = $dbh->iterate(
    'SELECT name FROM artist WHERE name LIKE ?', 'A%',
    sub ($row) { $row->[0] },
);
while (my($name) = $names->next) {
    say $name;
}

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

`use DBIx::Squirrel` takes the names the DBI exports, as `use DBI` does,
and the DBI exports them:

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

Given a database handle in place of a data source, `connect` makes a new
connection with the same parameters, using the DBI's `clone`. Any
attributes passed are applied to the new connection. The handle can come
from DBIx::Squirrel, from the DBI itself, or from code that made its own
connection, so a plain DBI handle can be turned into DBIx::Squirrel's:

```perl
my $plain = DBI->connect($data_source, $username, $password);
my $dbh   = DBIx::Squirrel->connect($plain);
```

The new handle keeps the first one's `ekorn_` defaults, with any passed
in their place. It's a separate connection, not a second name for the
first: it doesn't share the first one's transaction, temporary tables
or session settings. An in-memory SQLite database, for example, gives a
new, empty database.

### connect_cached

`connect_cached` is the DBI's own. It calls `connect` when it needs a
new connection, so it croaks on failure too. DBIx::Squirrel's own
attributes are part of the cache's key, so two calls with the same
attributes have the same handle, and calls with different ones don't.

### The dialect

Statements are read by the rules of the database they're for: where
strings start and end, and what's a comment (see
[Placeholders](#placeholders)). `connect` works out the dialect when it
isn't given one, in the `ekorn_dialect` attribute:

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
database and statement handle classes. The subclass needs both, as the
DBI requires, each a subclass of DBIx::Squirrel's:

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
for every statement the handle prepares; passed to `prepare` (or
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

A statement can use placeholders in any of these styles, which are
rewritten as `?` before the DBI sees them:

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
  are given as pairs or in a hash reference, with or without the sigil,
  and there must be a value for each name, and no other.

```perl
my $sth = $dbh->prepare('SELECT * FROM artist WHERE id = :id OR parent_id = :id');
$sth->execute(id => 2);
$sth->execute({':id' => 2});

$sth = $dbh->prepare('SELECT * FROM artist WHERE id = $1 OR parent_id = $1');
$sth->execute(2);
```

### What isn't a placeholder

Placeholders are looked for only in the SQL itself. These are left as
they are:

- anything inside a quoted string or identifier: `'10:30'`, `"a:b"`,
  `` `c?` ``;
- comments: `-- :x`, `/* $1 */`;
- PostgreSQL's dollar-quoted bodies: `$$ ... $$`, `$tag$ ... $tag$`;
- a cast, such as `x::int`;
- an identifier containing `$`, such as `v$session`.

To use a `?`, `:` or `$` that isn't a placeholder, such as one of
PostgreSQL's `?`, `?|` and `?&` operators, put a backslash before it, as
DBD::Pg allows. The backslash and the character after it are passed on
as they are, and DBD::Pg removes the backslash:

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
  recognised, and the statement is passed on as written, for DBD::Pg to
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

Blank space around the statement is removed; comments are passed on to
the database.

Unlike the DBI's `prepare`, it **always croaks** if the statement can't
be prepared, whatever `RaiseError` is set to, with the message the DBI
raises under `RaiseError`, such as
`DBD::SQLite::db prepare failed: near "SELEC": syntax error`.

A statement given as a string without attributes, as most are, is read
for placeholders once for each database handle, which keeps what it
found. The handle keeps up to 1000 statements, and starts again when it
has that many.

### prepare_cached

```perl
$sth = $dbh->prepare_cached($statement);
$sth = $dbh->prepare_cached($statement, \%attr);
$sth = $dbh->prepare_cached($statement, \%attr, $if_active);
```

As `prepare`, using the DBI's cache of statement handles. Its errors
name `prepare_cached`, as the DBI's do.

Two statements can be rewritten the same: `SELECT :a, :b` and
`SELECT :b, :a` both become `SELECT ?, ?`. Each still has a handle of
its own, as the statement as written is part of the cache's key. So are
DBIx::Squirrel's own attributes, so a statement prepared with
`{ekorn_slice => {}}` and one prepared without have different handles.

A cached handle that an iterator is part way through isn't handed out,
or finished, as the DBI would finish an active one, which would cut the
iterator's results short. A new handle is made instead, and cached in its
place, unless `$if_active` is 2, which asks for the cached handle as it
is. Otherwise, `$if_active` means what it does to the DBI: a cached
handle that's active, with no iterator, is finished, after a warning,
unless `$if_active` says otherwise.

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

The DBI doesn't finish a statement still active from an earlier
`execute` before executing it again, and nor does `execute`, unless the
`ekorn_finish_active` attribute is true, on the database handle or the
statement.

### bind

```perl
$sth = $sth->bind(@bind_values);
$sth = $sth->bind(\@bind_values);
$sth = $sth->bind(%values);
$sth = $sth->bind(\%values);
```

Binds values to the statement's placeholders without executing it, and
returns the statement handle, or nothing if the DBI couldn't bind a
value. How values are matched to placeholders depends on the
[style](#the-styles).

It croaks, at the caller's line, if the values don't match the
placeholders:

| Placeholders | Croaks when |
|---|---|
| numbered | There aren't as many values as the highest number: `Expected 2 bind values, not 1`. |
| named | There's an odd number of values: `Expected names and values in pairs`. |
| named | A name isn't one of the statement's: `Expected a placeholder of the statement (x)`. |
| named | A name has no value: `Expected a value for each placeholder (none for id)`. |

### An array reference of values

A single array reference stands for the values in it, so
`$sth->bind([1, 2])` is `$sth->bind(1, 2)`, and the same goes for
`execute`, `do` and the select methods.

The exception is DBD::Pg, which binds an array reference as a PostgreSQL
array. With DBD::Pg, an array reference given to a statement taking one
value, such as `SELECT * FROM artist WHERE id = ANY(?)`, is that value,
as it would be with the DBI. Through another driver, such as DBD::ODBC,
it's unwrapped as usual, as the driver can't bind arrays.

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
reference or `undef`. An array reference there is the
[values in it](#an-array-reference-of-values); any other reference
croaks: `Expected a reference to a HASH or ARRAY`.

```perl
$dbh->do('UPDATE artist SET name = :name WHERE id = :id', name => 'Blur', id => 2);
$dbh->do('UPDATE artist SET name = ? WHERE id = ?', ['Blur', 2]);
```

A statement with `?` placeholders, or none, goes to the driver's own
`do`, as with plain DBI, so the driver's row counts and options apply,
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
$ary_ref  = $dbh->selectrow_arrayref($statement, \%attr, @bind_values);
$hash_ref = $dbh->selectrow_hashref($statement, \%attr, @bind_values);
$ary_ref  = $dbh->selectall_arrayref($statement, \%attr, @bind_values);
$hash_ref = $dbh->selectall_hashref($statement, $key_field, \%attr, @bind_values);
$ary_ref  = $dbh->selectcol_arrayref($statement, \%attr, @bind_values);
```

Each works as the DBI's, preparing the statement as `prepare` does,
unless it's already a statement handle, and binding the values as
[`bind`](#bind) binds them. The DBI's `selectall_array` goes through
`selectall_arrayref`, so it does too. As with the DBI, the attributes
come before the bind values, and can be `undef`.

```perl
my $names = $dbh->selectcol_arrayref(
    'SELECT name FROM artist WHERE id IN ($1, $2)', undef, 1, 2,
);
```

Unlike `prepare`, they don't croak if the statement can't be prepared:
without `RaiseError`, each returns what the DBI's returns, `undef` or
nothing.

## Iterators

An iterator executes a statement and hands out its results one at a
time, each row run through a [pipeline](#pipelines) of stages.

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

The bind values are in any form `execute` takes. The **stages** are the
code references at the end of the arguments: each row is run through
them, and what comes out is the result. With no stages, the result is
the row.

```perl
my $it = $dbh->iterate(
    'SELECT id, name FROM artist WHERE name LIKE :pattern',
    pattern => 'A%',
    sub ($row) { $row->[1] },
);
while (my($name) = $it->next) {
    say $name;
}
```

The statement isn't executed until the first result is asked for, and
it's finished when the results run out, or when the iterator is ended
early, by a [stop](#stopping-a-pipeline) or by `single`.

Rows are fetched 100 at a time, with the DBI's `fetchall_arrayref`.

### Iterator methods

| Method | What it does |
|---|---|
| `next` | Returns the next result, or an empty list when there are no more. |
| `all` | Returns the results not yet handed out, or, in scalar context, how many there were. |
| `single` | Executes the statement again, and returns its one result, or nothing if it has none. It croaks if there's more than one: `Expected one result, not more`. |
| `reset` | Executes the statement again, ready to iterate from its first row, finishing it first if it's still active, and returns the iterator. |
| `count` | Returns the number of results handed out so far. |
| `sth` | Returns the statement handle. |

A stage can return `undef` as a result, so read `next` in list context,
as above, rather than testing whether what it returns is defined.

`reset` takes new bind values, which replace those given before, and
new stages, which are added to those given when the iterator was made.
Both are kept until others are given:

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
`connect`, it's the default for each statement the handle prepares;
given to `prepare` or `iterate`, it's for that statement.

```perl
my $it = $dbh->iterate(
    'SELECT id, name FROM artist', {ekorn_slice => {}},
    sub ($row) { "$row->{id}: $row->{name}" },
);
```

### One iterator to a statement handle

A statement handle can have one iterator going through its results at a
time. Executing another iterator over the same statement handle while
the first has results left croaks:
`Expected the statement handle's other iterator to be finished`. Read
the first to the end, or let it go out of scope, first.

## Result sets and row objects

### results

```perl
$results = $dbh->results($statement, \%attr, @bind_values, @stages);
$results = $dbh->results($statement, @bind_values, @stages);
$results = $sth->results(@bind_values, @stages);
```

As [`iterate`](#iterate), returning a `DBIx::Squirrel::Results`: an
iterator whose rows are objects, with a method for each column, named in
lower case. The stages see the objects. A result set has the iterator's
methods, and no others.

```perl
my $results = $dbh->results('SELECT id, Name FROM artist WHERE id <= ?', 10);
while (my($artist) = $results->next) {
    say $artist->id, ' ', $artist->name;
}

say $dbh->results('SELECT * FROM artist WHERE id = $1', 1)->single->name;
```

Rows are always fetched as arrays for a result set: the `ekorn_slice`
attribute doesn't apply.

### Row objects

Each row is an array, blessed into a class with a method for each
column. There's one class for each base class and list of column
names, made the first time a result set fetches rows with those
columns, and kept for the life of the program. A row needs nothing from
its result set, and can be kept after the result set has gone.

A column gets no method:

- if its name can't be a method's, such as `count(*)`;
- if the base class already has a method of that name, such as `can`,
  `isa`, `get_column`, or one of your own.

When two columns have one name, as in `SELECT a.id, b.id`, the method
is the first's. To give a column a method of its own, give it another
name in the statement, with `AS`:

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

Row classes are subclasses of `DBIx::Squirrel::Result`, or of the class
given in the `ekorn_result_class` attribute, which must itself be a
subclass of `DBIx::Squirrel::Result`. So rows can have methods of your
own:

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

A pipeline is a list of stages, each a code reference. Pipelines are how
iterators and result sets run their stages, and they can be used on
their own, with `DBIx::Squirrel::Pipeline`, or on a handle, with
[`pipe` and `tap`](#pipe-and-tap-on-handles).

### Stages

A stage is called with one value, as its argument and in `$_`, and
returns a list:

| A stage returns | It's a | The value |
|---|---|---|
| nothing | filter | is dropped. |
| one value | map | is replaced by that value, which goes on. |
| several values | flatMap | is replaced by each, which goes through the rest of the stages on its own. |

Each value goes through every stage before the next one starts, so the
values come out in order, and a stage sees them in the order a `for`
loop would. A stage returns whatever its last statement gives, so a
stage run for its side effects should still return what the next stage
needs.

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
with values, it returns the list that comes out of the last stage. With
no stages, it returns its values as they are. `new` croaks if a stage
isn't a code reference: `Expected stage #2 to be a code reference`.

`iterator` returns a closure handing out, one per call, the values that
come out of the stages. `$source` is a code reference returning the
next value or values on each call, and an empty list when there are no
more; it's called only when the values from its last call have all been
handed out. The closure returns an empty list when the values run out,
and on every call after that. Read it in list context, so an `undef`
value isn't mistaken for the end.

### When a stage dies

If a stage dies, the pipeline croaks at the line that called it, naming
the stage by its position, from `#1`, with the stage's message
indented:

```
Pipeline stage #2 failed at script.pl line 12:
    Illegal division by zero at script.pl line 8.
```

An exception object is passed on as it is.

## Stopping a pipeline

A stage can end a pipeline early and quietly by calling `Stop`. The rest
of that stage doesn't run, the values already out of the pipeline are
kept, any values the stop carries go on through the stages after it,
and nothing else is processed. An iterator that's stopped finishes its
statement.

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

`Stop` is exported by default; `DBIx::Squirrel::Stop->throw(@values)`
does the same without importing it. To keep `Stop` out of your
namespace:

```perl
use DBIx::Squirrel::Stop ();
```

### What a stop is

A stop is an exception: an array reference blessed into its class, whose
first element is the class and the rest the values it carries.
`throw` blesses it into the class it's called on, so a subclass of
`DBIx::Squirrel::Stop` throws one of its own, and a pipeline recognises
it with `isa`, so a subclass stops a pipeline too.

As a string, a stop is `Stop used outside a pipeline`, which is what a
user sees if one is thrown with nothing to catch it.

A stage that catches errors itself, with `eval` or `try`, should throw
a stop on again:

```perl
sub ($row) {
    try { ... }
    catch ($e) {
        die $e if $e isa 'DBIx::Squirrel::Stop';
        ...
    }
}
```

## What a stage can ask: Context

Inside a stage run by an iterator or result set, these functions say
what the stage might want to know about the result it's making, which it
can't work out from the value it's given. Outside a stage, they return
`undef`. None is exported by default.

```perl
use DBIx::Squirrel::Context qw(iterator result_number result_original);

my $it = $dbh->iterate(
    'SELECT name FROM artist ORDER BY name',
    sub ($row) { "@{[ result_number ]}. $row->[0]" },
);
```

| Function | Returns |
|---|---|
| `iterator` | The iterator running the stage. Its `sth` is the statement handle, and the statement handle's `Database`, the database handle. |
| `result_number` | The number of the result being made, from 1. It counts results, not rows: while a stage drops rows, the number stays the same, and each value a stage returns in place of one row is a result of its own. |
| `result_original` | The row the result is being made from, as it was fetched, before any stage changed it. For a result set, it's the row object. |

## pipe and tap on handles

Database and statement handles both have these methods. The examples use
a database handle; on a statement handle, the statement handle goes
through the stages instead.

### pipe

```perl
@results = $dbh->pipe(@stages);
$result  = $dbh->pipe(@stages);
```

Runs the handle through a pipeline of stages, and returns what comes out
of the last one: all of it in list context, or the first value in
scalar context, `undef` if there's none. To count the values instead:

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
side for their side effects, and returns the handle, so that a chain of
method calls can carry on after it. What comes out of the last stage is
dropped, and `tap` returns the handle however the stages end.

```perl
$dbh->tap(
    sub ($dbh)   { $dbh->selectrow_array('SELECT COUNT(*) FROM artist') },
    sub ($count) { log_count($count) },
)->do('DELETE FROM artist WHERE id = ?', undef, $id);
```

## A function for each database and statement: Sugar

`DBIx::Squirrel::Sugar` gives each database a name, and the package that
names it a function of that name, which returns the database handle or
runs a statement on it. It gives a statement a function too, which runs
it with the bind values and any stages given.

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
reference, and gives the package its function while the package is
compiled, so it can be called without parentheses. The arguments are
worked out then too: the environment, literals, and what a `BEGIN`
block has set are there, but a variable the program sets as it runs is
not yet.

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
anywhere in the program, connecting to it if it isn't connected.

Given a name and the arguments `connect` takes, defines a database by
that name, gives the calling package a function of that name, and
returns the function. A database defined with a database handle, in
place of a data source, is a clone of it, as `connect` makes, made when
it's first used.

A database is defined once in a program, by a name that can be a
function's, and the package can't have a function of that name already.

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
attributes to prepare it with. The statement can be a statement handle,
which is executed, or iterated over, itself.

```perl
my $sth   = music 'SELECT * FROM artist WHERE id = ?', 1;
my @names = music 'SELECT name FROM artist', sub ($row) { $row->[0] };
```

### statement

```perl
$function = statement($name, $database, $statement, @stages);
$function = statement($name, $database, $statement, \%attr, @stages);
```

Defines a statement by that name, on the database of that name, with
the attributes to prepare it with, and stages, if given; gives the
calling package a function of that name; and returns the function. The
database is found when the function runs, so it can be defined after
the statement.

### The function a statement is given

```perl
$sth     = artist(@bind_values);
@results = artist(@bind_values, @stages);
$count   = artist(@bind_values, @stages);
```

It executes the statement with the bind values, and returns the
statement handle, or nothing if it couldn't be executed. With stages,
its own or those given after the bind values, it iterates over the
results, through its own stages and then those given, and returns them
all, or how many there were in scalar context. Stages given are for that
call only.

```perl
my @all   = artist_names;                             # through its stage
my @upper = artist_names sub ($name) { uc $name };    # and one more
my $found = artist id => 1;                           # the statement handle
```

The statement is prepared once for each database handle, with
`prepare_cached`. While its handle is in use, by a statement handle not
read to the end, or by a stage calling the same function, a call
prepares one of its own.

### Connections

A database is connected to when it's first used, not when it's
defined, with `connect_cached`, so two databases defined with the same
arguments share a handle.

The handle is kept, and each use has the same one, without a ping to
the database each time. It's pinged only while its last call has
failed, which leaves the error to be read, and made again if the
connection has gone, or if the handle has been disconnected. So a
connection that drops between uses is noticed by the call after it,
which fails, as it would with plain DBI, and the call after that has a
new connection.

## Errors

Errors are reported at the line of your code that called DBIx::Squirrel,
never at a line inside it or the DBI. That includes the DBI's own errors
under `RaiseError`, such as
`DBD::SQLite::db prepare failed: near "SELEC": syntax error`, which keep
the DBI's message.

An error DBIx::Squirrel raises in the DBI's place, where it croaks and
the DBI would return `undef` (in `connect`, `prepare` and `prepare_cached`), has the
message the DBI raises under `RaiseError`, so an error reads the same
whatever `RaiseError` is set to.

Each error names the method you called, as plain DBI does: `do` and the
select methods, not the `prepare` or `execute` they call.

An error from a `HandleError` callback, or one that isn't a string, is
passed on as it was raised.

## Diagnostics

DBIx::Squirrel's own messages, each reported at the caller's line. Those
starting "Expected" say what was expected.

### Connecting, preparing and binding

| Message | Cause |
|---|---|
| `Expected a statement` | The statement was blank, or a reference other than those `prepare` takes. |
| `Expected one placeholder style, not several (%s)` | The statement mixed styles, such as `?` and `:name`; each is listed as an example. |
| `Expected placeholders numbered from 1 (%s)` | A numbered placeholder such as `$0`. |
| `Expected ekorn_slice to be a reference to an ARRAY or HASH` | `ekorn_slice` was something else. |
| `Expected a reference to a HASH or ARRAY` | The first argument after the statement in `do`, `iterate` or `results` was a reference, but not to a hash or an array. |
| `Expected %d bind values, not %d` | A statement with numbered placeholders was given more or fewer values than its highest number. |
| `Expected names and values in pairs` | A statement with named placeholders was given an odd number of values. |
| `Expected a placeholder of the statement (%s)` | A value was given for a placeholder the statement doesn't have. |
| `Expected a value for each placeholder (none for %s)` | A statement with named placeholders wasn't given a value for each name. |

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
| `Expected stage #%d to be a code reference` | Something passed as a stage wasn't a code reference. No stage runs. |
| `Expected a code reference` | The source given to a pipeline's `iterator` wasn't a code reference. |
| `Pipeline stage #%d failed at %s line %d:` | A stage died. The message it died with follows, indented. |
| `Stop used outside a pipeline` | `Stop` was called where no pipeline was running to catch it. |

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
| `Expected only stages after the statement for %s` | A statement's definition had something other than code references after the statement and its attributes. |
| `Expected no function of the name in %s already (%s)` | The package has a function of that name already. |

## Differences from plain DBI

Where DBIx::Squirrel and plain DBI do the same thing, they give the same
result. These are the places they differ.

| | Plain DBI | DBIx::Squirrel |
|---|---|---|
| Placeholders | `?`, and whatever the driver adds. | `?`, `?1`, `:1`, `$1`, `:name` and `$name`, rewritten as `?` for the DBI. |
| Numbered and named placeholders | Bound by position. | Bound once, by number or name, wherever they appear. |
| `connect` failing | Returns `undef`, unless `RaiseError`. | Always croaks, with the DBI's `RaiseError` message. |
| `prepare` failing | Returns `undef`, unless `RaiseError`. | Always croaks, with the DBI's `RaiseError` message. |
| Attributes in `do` | Required, or `undef`, before the bind values. | May be left out. |
| A lone array reference of bind values | A value. | The values in it, except with DBD::Pg for a statement taking one value. |
| Where errors are reported | The line inside the module that called the DBI. | The line of your code that called DBIx::Squirrel. |
| Statements | A string. | A string, lines in an array reference, a code reference returning either, or a statement handle. |
| Executing an active statement | Left to the driver. | The same, or finished first with `ekorn_finish_active`. |
| Iterators, result sets, pipelines | None. | `iterate`, `results`, `pipe`, `tap` and Sugar. |

## Upgrading from 1.x

DBIx::Squirrel 2.0 is a rewrite, not an update: code written for 1.x
needs changes before it runs on 2.0. The ideas carry over, so most
changes are a rename or a simpler call, but some methods keep their
names and change what they do, marked **in bold** below.

To stay on 1.x, which supports Perl 5.10.1 and later, install the last
version by its number:

```
cpanm DBIx::Squirrel@1.6.5
```

### Requirements and loading

| 1.x | 2.0 |
|---|---|
| Perl 5.10.1 or later. | Perl 5.36 or later. |
| Hard dependencies on Compress::Bzip2, Crypt::CBC, Dotenv, JSON::Syck, YAML::Syck and others. | DBI, Ref::Util, namespace::clean, and a few core modules. |
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
| Styles could be mixed. | One style to a statement; a mix croaks. |
| `--` comments were removed before the statement reached the database. | Comments are passed on to the database. |

Binding by name, as pairs or in a hash reference, with or without the
sigil, works as it did.

### do

| 1.x | 2.0 |
|---|---|
| **In list context, `do` returned the row count and the statement handle.** | `do` returns what the DBI's returns, in any context. Use `prepare` and `execute` for the handle. |

### Iterators and result sets

| 1.x | 2.0 |
|---|---|
| `it` and `iterator`, aliases of `iterate`. | `iterate` only. |
| `rs` and `resultset`, aliases of `results`. | `results` only. |
| `$dbh->iterate($sql, [@bind_values, @transforms])`: values and stages in one array reference. | Stages are the code references at the end of the arguments: `$dbh->iterate($sql, @bind_values, @stages)`. |
| **`next` put the result in `$_`**, as in `while ($it->next) { say $_->Name }`. | Nothing is put in `$_`: `while (my($row) = $it->next) { say $row->name }`. |
| **`all` in scalar context returned a reference to the results.** | `all` in scalar context returns how many there were: `my $results = [$it->all]`. |
| **`count` fetched the rest of the results and returned how many there were in all.** | `count` returns how many have been handed out so far, as 1.x's `count_fetched` did. To count them all: `my $n = $it->all`. |
| `count_fetched`. | `count`. |
| **`single` and `one` returned the first result, with a warning if there were more.** | `single` executes the statement again and returns its one result, croaking if there's more than one. `one` is gone. |
| `first`, `last` and `last_fetched`. | Gone: `single`, `next`, or a stage. |
| `remaining`. | `all`, which returns the results not yet handed out. |
| `start` and `iterate` on an iterator, to execute it with new bind values. | `reset(@bind_values, @stages)`. |
| `reset($slice, $cache_size)`, to change the slice or the cache size. | `reset` takes bind values and stages. The slice is the `ekorn_slice` attribute; rows are fetched 100 at a time. |
| `slice`, `cache_size` and their package-wide defaults, `$DBIx::Squirrel::it::DEFAULT_SLICE` among them. | The `ekorn_slice` attribute, on `connect` or `prepare`. |
| `is_active`, `not_active` and `rows`. | Gone: `$it->sth->{Active}` and `$it->sth->rows`. |

### Rows as objects

| 1.x | 2.0 |
|---|---|
| **A column's method matched its name in any case:** `$row->ArtistId` or `$row->artistid`. | Methods are named in lower case only: `$row->artistid`. |
| Methods were made the first time each was called. | A class with a method for each column is made for each list of columns. See [Row objects](#row-objects). |
| A column whose name can't be a method's, such as `COUNT(*)`, was reached by its position. | By its position still, as rows are arrays, or with `get_column`, or given a name with `AS`. |

### Transformations, now stages

The stages work as transformations did: each gets a value as its
argument and in `$_`, and returns nothing to drop it, one value, or
several. These have changed:

| 1.x | 2.0 |
|---|---|
| `use DBIx::Squirrel::it qw(...)`, for what a stage can ask. | `use DBIx::Squirrel::Context qw(...)`. |
| `iterator`, `result_number` and `result_original`. | The same, from DBIx::Squirrel::Context. |
| `database` and `statement`. | `iterator->sth->{Database}` and `iterator->sth`. |
| `result` and `result_current`. | The stage's argument. |
| `result_first`, `result_prev`, `result_previous` and `result_offset`. | Gone. A stage that needs them keeps them itself. |
| No way to end a transformation early. | `Stop`, from DBIx::Squirrel::Stop. See [Stopping a pipeline](#stopping-a-pipeline). |

### Gone, out of scope

These have no place in 2.0. Any that come back will come back as
distributions of their own.

| 1.x | Instead |
|---|---|
| `DBIx::Squirrel::Crypt::Fernet`, and `decrypt` from DBIx::Squirrel::util. | A Fernet module from CPAN. |
| `DBIx::Squirrel::Transform::*` (Data::Dumper, IO, JSON::Syck, YAML::Syck). | A stage of your own calling the module. |
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
| `DBIx::Squirrel::Context` | What a stage can ask about the result it's making. |
| `DBIx::Squirrel::Sugar` | A function for each database and statement. |
| `DBIx::Squirrel::Placeholders` | Finds the placeholders in a statement. |
| `DBIx::Squirrel::Errors` | Reports errors at the caller's line. Internal. |
| `DBIx::Squirrel::Util` | Helpers the modules share. Internal. |
