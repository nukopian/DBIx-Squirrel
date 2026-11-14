# DBIx::Squirrel reference

<!-- stopwords: flatMap -->

DBI, minus the boilerplate, plus a pipeline.

With DBIx::Squirrel, you still write SQL, as you do with the DBI. It
takes away the friction around it: placeholders in whatever style you
like, lists of values, iterators over results, rows as objects, and a
pipeline of stages written beside the query. It's a subclass of the
DBI, so everything the DBI does still works. Where the two do the same
thing, they give the same result.

This reference describes every method, attribute, function and
message, and the protocols other code can rely on. Its chapters follow
the [user guide](HOWTO.md)'s, a layer at a time from the DBI up, and
each links to its chapter there: the guide is the tour, this is the
map. Each module's own POD says the same things more briefly. Where
the two differ, the POD is the authority. Every example runs, against
the database below, and its comments say what it prints.

This is version 3. [Upgrading from 2.x](#upgrading-from-2x) and
[Upgrading from 1.x](#upgrading-from-1x) list what changes for code
written for earlier versions.

## Contents

- [The examples' database](#the-examples-database)
- [At a glance](#at-a-glance)
- [Importing: DBIx::Squirrel::Tooling](#importing-dbixsquirreltooling)
- [1. Connecting](#1-connecting)
- [2. Placeholders](#2-placeholders)
- [3. Preparing, binding and running](#3-preparing-binding-and-running)
- [4. Iterators](#4-iterators)
- [5. Stages and Context](#5-stages-and-context)
- [6. Stopping a pipeline](#6-stopping-a-pipeline)
- [7. Gathering: stages made for each run](#7-gathering-stages-made-for-each-run)
- [8. Sinks](#8-sinks)
- [9. Result sets and row objects](#9-result-sets-and-row-objects)
- [10. Pipelines](#10-pipelines)
- [11. Operators: | and @{}](#11-operators--and-)
- [12. Sugar: a function for each database and statement](#12-sugar-a-function-for-each-database-and-statement)
- [13. Caching and connections](#13-caching-and-connections)
- [14. Writing stages, and functions that take them](#14-writing-stages-and-functions-that-take-them)
- [15. Protocols](#15-protocols)
- [16. Errors and diagnostics](#16-errors-and-diagnostics)
- [Differences from plain DBI](#differences-from-plain-dbi)
- [Upgrading from 2.x](#upgrading-from-2x)
- [Upgrading from 1.x](#upgrading-from-1x)
- [The modules](#the-modules)

## The examples' database

The examples run against this SQLite database, the user guide's, a
file called `music.db`. They follow on from each other, so `$dbh` is
this handle wherever it appears. It imports everything from
[DBIx::Squirrel::Tooling](#importing-dbixsquirreltooling), so the
examples needn't.

```perl
use v5.36;
use DBIx::Squirrel;
use DBIx::Squirrel::Tooling qw(:all);    # every stage, sink and word

my $dbh = DBIx::Squirrel->connect('dbi:SQLite:dbname=music.db', {RaiseError => 1, PrintError => 0});

$dbh->do("DROP TABLE IF EXISTS $_") for qw(track album artist);
$dbh->do('CREATE TABLE artist (id INTEGER PRIMARY KEY, name TEXT)');
$dbh->do('CREATE TABLE album  (id INTEGER PRIMARY KEY, artist_id INTEGER, title TEXT, year INTEGER)');
$dbh->do('CREATE TABLE track  (id INTEGER PRIMARY KEY, album_id INTEGER, name TEXT, plays INTEGER)');

$dbh->do('INSERT INTO artist (name) VALUES (?)', $_) for 'Abba', 'Blur', 'Cream';
$dbh->do('INSERT INTO album (artist_id, title, year) VALUES (?, ?, ?)', @$_)
    for [1, 'Arrival', 1976], [2, 'Parklife', 1994], [2, 'The Great Escape', 1995],
        [3, 'Disraeli Gears', 1967];
$dbh->do('INSERT INTO track (album_id, name, plays) VALUES (?, ?, ?)', @$_)
    for [1, 'Dancing Queen', 9100], [1, 'Knowing Me, Knowing You', 4200],
        [2, 'Girls & Boys', 6100], [2, 'Parklife', 5800],
        [3, 'Country House', 3900], [4, 'Sunshine of Your Love', 7700];
```

## At a glance

```perl
use DBIx::Squirrel::Tooling qw(:all);    # every stage, sink and word

# Placeholders in the style you like: ?, ?1, :1, $1, :name or $name
my $sth = $dbh->prepare('SELECT name FROM artist WHERE id = :id');
$sth->execute(id => 2);
say $sth->fetchrow_arrayref->[0];    # Blur

# A placeholder with ... takes a list: a ? for each of its values
my $names = $dbh->selectcol_arrayref('SELECT name FROM artist WHERE id IN (...:ids) ORDER BY id', ids => [1, 3]);
say "@$names";    # Abba Cream

# An iterator over the rows, read as they're wanted
my $it = $dbh->iterate('SELECT name FROM artist ORDER BY id');
while (my($row) = $it->next) {
    say $row->[0];
}
# Abba
# Blur
# Cream

# Stages beside the query, and a sink last to say what comes back
my @top = $dbh->iterate(
    'SELECT name FROM track ORDER BY plays DESC',
    pluck('name'),
    take(2),
    keep_all,
);
say join ', ', @top;    # Dancing Queen, Sunshine of Your Love

say $dbh->iterate('SELECT * FROM track WHERE plays > ?', 6000, count_items);    # 3

# Each row as an object, with a method for each column
say $dbh->results('SELECT * FROM album WHERE id = ?', 2)->first->title;    # Parklife
```

## Importing: DBIx::Squirrel::Tooling

<!-- not run -->
```perl
use DBIx::Squirrel::Tooling qw(:all);               # everything below
use DBIx::Squirrel::Tooling qw(:stages :sinks);     # or some tags
use DBIx::Squirrel::Tooling qw(pluck keep_all);     # or some names
```

What a caller uses to do work is made in several modules, each
described below. DBIx::Squirrel::Tooling exports all of it, from one
place, by Ekorn::Pipeline::Tooling's tags, with DBIx::Squirrel's own
`:rows` and `:context` besides:

| Tag | Holds | Made in |
|---|---|---|
| `:core` | `Stop`, `gather` | [Stop](#6-stopping-a-pipeline), [Gather](#7-gathering-stages-made-for-each-run) |
| `:flow` | `take`, `take_first`, `take_last`, `take_single`, `take_if`, `take_while`, `drop`, `drop_if`, `drop_while` | [Stages::Flow](#taking-and-dropping) |
| `:batch` | `batch`, `collect` | [Stages::Batch](#batching-and-collecting) |
| `:taps` | `peek`, `count_into`, `dump_to` | [Stages::Taps](#canned-stages) |
| `:rows` | `pluck`, `as_hash` | [Stages::Rows](#canned-stages) |
| `:stages` | `:flow`, `:batch`, `:taps` and `:rows` | |
| `:context` | `iterator`, `result_number`, `result_original` | [Context](#context) |
| `:sources` | `from_array`, `from_fh`, `from_file`, `counter` | Ekorn::Pipeline::Sources |
| `:sinks` | `count_items`, `keep`, `keep_all`, `keep_first`, `keep_last`, `keep_single`, `to_fh`, `to_file` | [Sinks](#8-sinks) |
| `:words` | `pipeline`, `stage`, `gather`, `source`, `generator`, `yield`, `sink_one`, `sink_many` | Ekorn::Pipeline::Factories |
| `:all` | all of the above | |

- **Nothing by default.** Ask for tags, names, or both. An unknown tag
  or name is Exporter's error: it warns `"%s" is not defined in
  %DBIx::Squirrel::Tooling::EXPORT_TAGS`, or `"%s" is not exported by
  the DBIx::Squirrel::Tooling module`, and dies `Can't continue after
  import errors`.
- **The same subs.** Each name is the sub its own module exports,
  prototype and all, so `take_if { ... }` and `stage { ... }` parse as
  they do imported from there, and importing a name from both does no
  harm.
- **DBIx::Squirrel's, where both export a name.** Each name comes from
  DBIx::Squirrel's own module where it has one, and from
  Ekorn::Pipeline's only where it has none. Today each name both
  export is the same sub, so importing Ekorn::Pipeline::Tooling too,
  in either order, gives the same subs. A test fails if that changes.
- **What's left out.** What's for extending DBIx::Squirrel rather than
  using it, such as `croakf`, from DBIx::Squirrel::Errors, and
  `is_stage`, from Ekorn::Pipeline; [the
  Sugar](#12-sugar-a-function-for-each-database-and-statement), whose
  `use` makes functions; and [`|`](#11-operators--and-), which only
  `use Ekorn::Pipeline::Operators` puts in force, in its own scope.
- **What a tag holds is public.** A name may be added to one in a
  release that only adds, but is dropped or renamed only in a major
  release.

## 1. Connecting

The user guide's [chapter 1](HOWTO.md#1-still-the-dbi).

### Importing

`use DBIx::Squirrel` takes the names the DBI exports, as `use DBI`
does, and the DBI exports them:

```perl
use DBIx::Squirrel qw(:sql_types neat);

say SQL_INTEGER;    # 4
say neat('Abba');   # 'Abba'
```

### connect

<!-- not run -->
```perl
$dbh = DBIx::Squirrel->connect($data_source, $username, $password);
$dbh = DBIx::Squirrel->connect($data_source, $username, $password, \%attr);
$dbh = DBIx::Squirrel->connect($data_source, \%attr);
$dbh = DBIx::Squirrel->connect($dbh, \%attr);
```

`connect` connects to a data source, as the DBI's `connect` does, and
returns a database handle, a `DBIx::Squirrel::db`. Its statement
handles are `DBIx::Squirrel::st`s. Both are subclasses of the DBI's
own, so they do everything the DBI's handles do.

The username and password can be left out, with the attributes
straight after the data source.

Unlike the DBI's `connect`, it **always croaks** if the connection
fails, whatever `RaiseError` is set to. The message is the one the DBI
raises under `RaiseError`, such as
`DBIx::Squirrel connect('dbname=music.db','',...) failed: ...`, and
it's reported at the line that called `connect`. The DBI returns
`undef` without `RaiseError`.

```perl
eval { DBIx::Squirrel->connect('dbi:NoSuchDriver:x', {RaiseError => 0, PrintError => 0}) };
say $@ ? 'croaked' : 'returned';    # croaked
```

### Connecting with an existing handle

Given a database handle in place of a data source, `connect` makes a
new connection with the same parameters, using the DBI's `clone`. Any
attributes passed are applied to the new connection. The handle can
come from DBIx::Squirrel, from the DBI itself, or from code that made
its own connection. So a plain DBI handle can be turned into
DBIx::Squirrel's:

```perl
use DBI;

my $plain    = DBI->connect('dbi:SQLite:dbname=music.db', '', '', {RaiseError => 1});
my $squirrel = DBIx::Squirrel->connect($plain);
say ref $squirrel;    # DBIx::Squirrel::db
```

The new handle keeps the first one's `ekorn_` defaults. Any passed
take their place. It's a separate connection, not a second name for
the first. It doesn't share the first one's transaction, temporary
tables or session settings. An in-memory SQLite database, for example,
gives a new, empty database.

### DBIx::Squirrel's own attributes

Attributes whose names start `ekorn_` are DBIx::Squirrel's own. They
aren't passed on to the DBI. Passed to `connect`, they're the defaults
for every statement the handle prepares. Passed to `prepare` (or
`prepare_cached`, `do`, `iterate`, `results` and the select methods),
they override those defaults for one statement.

| Attribute | What it does |
|---|---|
| `ekorn_dialect` | The database whose rules statements are read by, such as `mysql` or `Pg`. `connect` works it out when it isn't given. See [The dialect](#the-dialect). |
| `ekorn_finish_active` | When true, a statement still active from an earlier `execute` is finished before it's executed again. See [execute](#execute). |
| `ekorn_slice` | The shape an iterator fetches rows in: an array reference for arrays, the default, or a hash reference for hashes. See [Rows as arrays or hashes](#rows-as-arrays-or-hashes). |
| `ekorn_result_class` | The base class of a result set's row objects, a subclass of `DBIx::Squirrel::Result`. See [Methods of your own](#methods-of-your-own). |

```perl
my $hashes = DBIx::Squirrel->connect('dbi:SQLite:dbname=music.db', {
    RaiseError  => 1,
    ekorn_slice => {},    # iterators fetch hashes, by default
});
say $hashes->iterate('SELECT name FROM artist WHERE id = 1')->first->{name};                        # Abba
say $hashes->iterate('SELECT name FROM artist WHERE id = 1', {ekorn_slice => []})->first->[0];    # Abba
```

### The dialect

Statements are read by the rules of the database they're for: where
strings start and end, and what's a comment (see
[Placeholders](#2-placeholders)). The dialect is given in the
`ekorn_dialect` attribute. When it isn't, `connect` works it out:

- It's the driver's own name, such as `SQLite`, `mysql` or `Pg`.
- A driver that passes the connection on to another database
  (DBD::ADO, DBD::Gofer, DBD::JDBC, DBD::ODBC or DBD::Proxy) is asked,
  through the DBI's `get_info`, what the database is. MariaDB, MySQL,
  PostgreSQL and SQLite are recognised.
- Any other database, or one that doesn't say, is read by the standard
  rules.

Name the dialect when `connect` can't tell:

<!-- not run -->
```perl
$dbh = DBIx::Squirrel->connect($odbc_data_source, $username, $password, {ekorn_dialect => 'mysql'});
```

### Subclassing

Called on a subclass of DBIx::Squirrel, `connect` uses that subclass's
database and statement handle classes. The DBI requires the subclass
to have both, and each must be a subclass of DBIx::Squirrel's:

```perl
package My::Squirrel     { our @ISA = 'DBIx::Squirrel' }
package My::Squirrel::db { our @ISA = 'DBIx::Squirrel::db' }
package My::Squirrel::st { our @ISA = 'DBIx::Squirrel::st' }

my $mine = My::Squirrel->connect('dbi:SQLite:dbname=music.db', {RaiseError => 1});
say ref $mine;    # My::Squirrel::db
```

Without them, the DBI warns that the subclass isn't set up, and
returns its own handles.

## 2. Placeholders

The user guide's [chapter 2](HOWTO.md#2-writing-statements).

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

A statement uses **one style** throughout. `prepare` croaks if it
finds more than one, listing each as an example:
`Expected one placeholder style, not several (?, :name)`.

The same placeholder can appear more than once:

- A **numbered** placeholder is bound once, wherever it appears. In
  `SELECT $2 + $1, $1`, the values `(10, 20)` give
  `SELECT 20 + 10, 10`. There must be as many values as the highest
  number, and numbers start from 1.
- A **named** placeholder is bound by name, wherever it appears.
  Values are given as pairs or in a hash reference, with or without
  the sigil. There must be a value for each name, and no other.

```perl
say join ' ', $dbh->selectrow_array('SELECT $2 + $1, $1', 10, 20);    # 30 10

my $sth = $dbh->prepare('SELECT name FROM artist WHERE id = :id OR id = :id + 10');
$sth->execute(id => 2);
say $sth->fetchrow_arrayref->[0];    # Blur
$sth->execute({':id' => 3});
say $sth->fetchrow_arrayref->[0];    # Cream
```

### Lists

A placeholder with `...` before it takes a list. It's written as a `?`
for each of its values, separated by commas. Use it for `IN`, and
anywhere else SQL takes a list of values:

```perl
my $names = $dbh->selectcol_arrayref('SELECT name FROM artist WHERE id IN (...:ids) ORDER BY id', ids => [1, 2]);
say "@$names";    # Abba Blur
```

Any style can take a list: `...?`, `...?1`, `...:1`, `...$1`,
`...:name` or `...$name`. The list is a reference to an array of at
least one plain value. It's given as any other value is: by name, or
in order. Given to a statement whose one value is a list, a single
array reference is the list, not the values in it:

```perl
my $one = $dbh->selectcol_arrayref('SELECT name FROM artist WHERE id IN (...?) ORDER BY id', [1, 3]);
say "@$one";    # Abba Cream

my $two = $dbh->selectcol_arrayref('SELECT name FROM artist WHERE name = ? OR id IN (...?) ORDER BY id', 'Abba', [2]);
say "@$two";    # Abba Blur
```

- **It's prepared with its values.** How many values a list has
  decides the statement the DBI prepares. So a statement taking a list
  is prepared by a method given its values: `do`, the select methods,
  `iterate`, `results`, and the Sugar's functions. `prepare` and
  `prepare_cached` croak:
  `Expected bind values with a statement taking a list (...:ids)`.
- **A list has at least one plain value.** An empty list croaks, as
  `IN ()` isn't SQL, so the empty case is left to you:
  `Expected at least one value in a list (...:ids)`. So does a plain
  value or `undef` in place of a list. So does a list holding a
  reference, such as `[[1, 2, 3]]` to a statement whose one value is a
  list.
- **A placeholder takes a list everywhere it's used, or nowhere.**
  Used twice, it takes its list in both places.
- **Its handle is for lists of the lengths it was prepared for.** The
  statement handle of a statement taking a list, such as an iterator's
  `sth`, can be executed again with lists of the same lengths. Given
  another length, it croaks. An iterator's [`reset`](#reset) prepares
  the statement again, on a new handle, when a list has a different
  number of values. A Sugar statement taking a list isn't cached, as
  each length makes a different statement.
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

```perl
my $row = $dbh->selectrow_arrayref(q{SELECT '10:30', :name -- not :a placeholder}, undef, name => 'Abba');
say "@$row";    # 10:30 Abba
```

To use a `?`, `:` or `$` that isn't a placeholder, put a backslash
before it, as DBD::Pg allows. PostgreSQL's `?`, `?|` and `?&`
operators are examples. The backslash and the character after it are
passed on unchanged, and DBD::Pg removes the backslash:

<!-- not run -->
```perl
$pg->prepare(q{SELECT * FROM doc WHERE data \? 'key' AND id = :id});
```

### Strings, by dialect

Strings are read by the rules of the handle's [dialect](#the-dialect):

- With `mysql` and `MariaDB`, a backslash escapes a character in a
  string (`'it\'s'`), `"..."` is a string, and `#` starts a comment.
  MySQL's `NO_BACKSLASH_ESCAPES` mode isn't noticed.
- With other dialects, a backslash is an ordinary character in a
  string (`'C:\'`), except in PostgreSQL's `E'...'` strings.

To read one statement as another dialect, give it `ekorn_dialect`:

<!-- not run -->
```perl
$dbh->prepare($statement, {ekorn_dialect => 'mysql'});
```

### DBD::Pg's own options

DBD::Pg's placeholder options are followed, whether set on the
database handle or passed to `prepare`:

- With `pg_placeholder_dollaronly`, only `$1`-style placeholders are
  recognised. The statement is passed on as written, for DBD::Pg to
  read and bind.
- With `pg_placeholder_nocolons`, the `:1` and `:name` styles aren't
  placeholders, so array slices such as `data[:2]` are left alone.

## 3. Preparing, binding and running

The user guide's [chapter
3](HOWTO.md#3-binding-values-and-running-statements).

### prepare

<!-- not run -->
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

```perl
my $sth = $dbh->prepare(['SELECT title', 'FROM album', 'WHERE id = ?']);
$sth->execute(1);
say $sth->fetchrow_arrayref->[0];    # Arrival

my $again = $dbh->prepare(sub { 'SELECT name FROM artist WHERE id = ?' });
$again->execute(3);
say $again->fetchrow_arrayref->[0];    # Cream
```

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

### execute

<!-- not run -->
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
placeholder unbound, which most drivers read as `NULL`. `do`,
iterators and the select methods check the same way:

```perl
my $sth = $dbh->prepare('SELECT name FROM artist WHERE id = :id');
eval { $sth->execute };
print $@;    # Expected a value for each placeholder (none for id) at ... line ...

$sth->bind_param(id => 1);
$sth->execute;
say $sth->fetchrow_arrayref->[0];    # Abba
```

The DBI doesn't finish a statement still active from an earlier
`execute` before executing it again. Nor does `execute`, unless the
`ekorn_finish_active` attribute is true, on the database handle or the
statement.

### bind

<!-- not run -->
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

```perl
my $sth = $dbh->prepare('SELECT name FROM track WHERE plays > :plays ORDER BY plays DESC');
$sth->bind(plays => 8000)->execute;
say $sth->fetchrow_arrayref->[0];    # Dancing Queen
```

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
  DBD::Pg, an array reference given to a statement taking one value,
  such as `SELECT * FROM artist WHERE id = ANY(?)`, is that value, as
  it would be with the DBI. Through another driver, such as DBD::ODBC,
  it's unwrapped as usual, as the driver can't bind arrays.

### bind_param

<!-- not run -->
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
- by name, for named placeholders, with or without the sigil: `'id'`
  or `':id'`;
- by position, for named placeholders too, as with the DBI.

The value is bound to every use of the placeholder in the statement.
The value for a [list](#lists) is the list. Each value in it is bound
to a position of its own.

```perl
my $sth = $dbh->prepare('SELECT :a + :a, :b');
$sth->bind_param(a => 2);
$sth->bind_param(':b', 3);
$sth->execute;
say join ' ', @{ $sth->fetchrow_arrayref };    # 4 3
```

### do

<!-- not run -->
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
reference or `undef`. An array reference there stands for the [values
in it](#an-array-reference-of-values). Any other reference croaks:
`Expected a reference to a HASH or ARRAY`.

```perl
$dbh->begin_work;
say $dbh->do('UPDATE artist SET name = :name WHERE id = :id', name => 'BLUR', id => 2);    # 1
say $dbh->do('UPDATE artist SET name = ? WHERE id = ?', ['Blur', 2]);                       # 1
$dbh->rollback;
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
[iterator](#4-iterators), or the select methods, for those.

### The select methods

<!-- not run -->
```perl
@row_ary  = $dbh->selectrow_array($statement, \%attr, @bind_values, @stages);
$ary_ref  = $dbh->selectrow_arrayref($statement, \%attr, @bind_values, @stages);
$hash_ref = $dbh->selectrow_hashref($statement, \%attr, @bind_values, @stages);
$ary_ref  = $dbh->selectall_arrayref($statement, \%attr, @bind_values, @stages);
@rows     = $dbh->selectall_array($statement, \%attr, @bind_values, @stages);
$hash_ref = $dbh->selectall_hashref($statement, $key_field, \%attr, @bind_values, @stages);
$ary_ref  = $dbh->selectcol_arrayref($statement, \%attr, @bind_values, @stages);
```

Without stages, each works as the DBI's does. It prepares the
statement as `prepare` does, unless it's already a statement handle,
and binds the values as [`bind`](#bind) binds them. `selectall_array`
gives the rows `selectall_arrayref` gives, as a list, as the DBI's
does.

As with [`do`](#do), the attributes may be left out. The first
argument after the statement, or after `selectall_hashref`'s key
field, is taken as the attributes only if it's a hash reference or
`undef`. So named values given in a hash reference, or a first value
that's `undef`, need the attributes, or `undef`, in front.

**Given stages after the bind values,** each pushes what the DBI's
method returns through them, as a pipeline called with values does,
and returns what comes out of the last: every value; or, where one
value is asked for, a sink's result, if a sink is last, and otherwise
how many values came out. `selectrow_array` pushes the row's values,
`selectall_array` each row, and the others their one reference. As a
pushed run has no statement as its source, the stages can't use
`pluck` by a name for an array row, or `as_hash`.

```perl
my @names = $dbh->selectall_array(
    'SELECT name FROM artist ORDER BY id',
    sub { $_->[0] },
    sub {uc},
);
say "@names";    # ABBA BLUR CREAM

say scalar $dbh->selectall_array('SELECT * FROM artist', sub { $_->[0] > 1 ? $_ : () });    # 2

my $col = $dbh->selectcol_arrayref('SELECT name FROM artist WHERE id IN ($1, $2) ORDER BY id', 1, 2);
say "@$col";    # Abba Blur
```

Unlike `prepare`, they don't croak if the statement can't be prepared.
Without `RaiseError`, each returns what the DBI's returns, `undef` or
nothing.

## 4. Iterators

The user guide's [chapter
4](HOWTO.md#4-a-statement-as-a-source-of-rows).

An iterator treats a statement as a source of rows, read only as
they're wanted. Each row is run through the iterator's
[stages](#5-stages-and-context), if any, and what comes out is a
result. With no stages, the result is the row.

### iterate

<!-- not run -->
```perl
$it     = $dbh->iterate($statement, \%attr, @bind_values, @stages);
$it     = $dbh->iterate($statement, @bind_values, @stages);
$it     = $sth->iterate(@bind_values, @stages);
@result = $dbh->iterate($statement, @bind_values, @stages, $sink);
```

On a database handle, `iterate` prepares the statement, as `prepare`
does, and returns a `DBIx::Squirrel::Iterator` over its results. As
with `do`, the attributes may be left out. On a statement handle, it
returns an iterator over that statement's results.

The bind values are in any form `execute` takes. The **stages** are at
the end of the arguments: code references, pipelines, or any of
Ekorn::Pipeline's stages. Each row is run through them, in order. See
[Stages](#stages).

**A sink given last says what comes back.** If the last stage is one
of Ekorn::Pipeline's [sinks](#8-sinks), `iterate` reads the run to its
end and returns the sink's result, not an iterator.

```perl
my $it = $dbh->iterate('SELECT name FROM artist WHERE name LIKE :pattern ORDER BY id', pattern => '%r%', sub { $_->[0] });
while (my($name) = $it->next) {
    say $name;
}
# Blur
# Cream
```

The statement isn't executed until the first result is asked for. It's
finished when the results run out, when the run is ended early, by a
[stop](#6-stopping-a-pipeline), or by `first` or `single`, and when
the iterator is let go.

### How rows are fetched

Rows are fetched with the DBI's `fetchall_arrayref`, 2 at first, the
least that tells whether there's a second, then twice as many each
time a fetch fills its batch, up to 64. So reading one row fetches no
more than two, and a large result is never held all at once.

Without stages, `all` takes what's left of the batch and fetches the
rest at once. That's nearly as quick as the DBI's own
`selectall_arrayref`. With stages, each row goes through them in turn,
which costs a little for each row. So to change every row of a large
result, when nothing needs to stop early, `map` over `all` is quicker
than a stage:

```perl
my @names = map { $_->[0] } $dbh->iterate('SELECT name FROM artist ORDER BY id')->all;
say "@names";    # Abba Blur Cream
```

### The iterator's methods

| Method | What it does |
|---|---|
| `next` | Returns the next result, or an empty list when there are no more. |
| `all` | Returns the results still to come, reading the run to its end: as a list, or, asked for one value, an array reference of them, never a count. The statement is then finished. Without stages, it fetches the rest at once. |
| `first` | Returns the next result, or `undef` if there's none, and finishes the statement. |
| `single` | Returns the next result, or `undef` if there's none, and finishes the statement. If there's another, it warns, `Expected only one item, but there were more`, and returns the first: for a statement that lost its `LIMIT 1`. |
| `ended` | Returns how the last run ended: `done`, `stopped` or `died`; nothing while a run is going, or before one has started. |
| `reset` | Runs the statement again, from its first row, and returns the iterator. See [reset](#reset). |
| `column_names` | Returns the names of the statement's columns, as `fetchrow_hashref` would key them, following `FetchHashKeyName`. They're read when the statement is executed, as DBD::mysql gives none once the last row is fetched. |
| `sth` | Returns the statement handle. It changes when `reset` prepares a statement taking a list again. |

A stage can return `undef` as a result. So read `next` in list
context, as below, rather than testing whether what it returns is
defined. `all`, `first` and `single` take what's left of the run, so
after `next` they start from the next result:

```perl
my $it = $dbh->iterate('SELECT name FROM artist ORDER BY id', sub { $_->[0] });
my($abba) = $it->next;
say $abba;                  # Abba
say join ' ', $it->all;     # Blur Cream
say $it->ended;             # done

say $dbh->iterate('SELECT name FROM artist ORDER BY id', sub { $_->[0] })->first;    # Abba
say $dbh->iterate('SELECT COUNT(*) FROM track', sub { $_->[0] })->single;          # 6
say join ', ', $dbh->iterate('SELECT id, title AS Album FROM album')->column_names;    # id, Album
```

`ended` is `done` when the rows ran out, `stopped` when the run was
cut short, by `first`, by `single` finding a second result, or by a
stage that stopped, and `died` when a stage died. A run read with `|`
or `@{}` is the iterator's last run too (see [11.
Operators](#11-operators--and-)).

### reset

<!-- not run -->
```perl
$it = $it->reset;
$it = $it->reset(@bind_values, @stages);
```

Executes the statement again, ready to iterate from its first row, and
returns the iterator. If the statement is still active, it's finished
first, and whatever the run before held goes with it. Bind values
given replace those given before. Stages given are added to those
given when the iterator was made. Both are kept until others are
given:

```perl
my $it = $dbh->iterate('SELECT name FROM artist WHERE id > ? ORDER BY id', 0, sub { $_->[0] });
say join ' ', $it->all;                      # Abba Blur Cream
say join ' ', $it->reset(1)->all;            # Blur Cream
say join ' ', $it->reset(sub {lc})->all;     # blur cream
```

A statement taking a [list](#lists) is prepared again, on a new
statement handle, if a list given has a different number of values
from the one before. `sth` then returns the new handle.

### Rows as arrays or hashes

Rows are fetched as arrays, unless the `ekorn_slice` attribute says
otherwise. It's a slice as the DBI's `fetchall_arrayref` takes it: an
array reference for arrays, or a hash reference for hashes. Given to
`connect`, it's the default for each statement the handle prepares.
Given to `prepare` or `iterate`, it's for that statement.

```perl
my $it = $dbh->iterate('SELECT id, name FROM artist ORDER BY id', {ekorn_slice => {}}, sub { "$_->{id}: $_->{name}" });
say join ', ', $it->all;    # 1: Abba, 2: Blur, 3: Cream
```

### One iterator to a statement handle

A statement handle can have only one iterator going through its
results at a time. While the first has results left, executing another
over the same handle croaks:
`Expected the statement handle's other iterator to be finished`. Read
the first to the end, or let it go out of scope, first. An iterator
that's let go ends its run, and finishes its statement.

## 5. Stages and Context

The user guide's [chapter
5](HOWTO.md#5-stages-shaping-rows-on-the-way-out).

### Stages

A stage is given one value, as its argument and in `$_`, and returns a
list. Write it whichever way reads best: name the value with a
signature, or leave the signature out and use `$_`:

<!-- not run -->
```perl
sub ($row) { $row->[1] }    # the value, named
sub { $_->[1] }             # the same, in $_
```

`$_` is localised for each call, so your own `$_` is unchanged.

| A stage returns | It's a | The value |
|---|---|---|
| nothing | filter | is dropped. |
| one value | map | is replaced by that value, which goes on. |
| several values | flatMap | is replaced by each, which goes through the rest of the stages on its own. |

Each value goes through every stage before the next one starts. So the
values come out in order. A stage returns whatever its last statement
gives, so a stage run for its side effects should still return what
the next stage needs.

```perl
my @words = $dbh->iterate(
    'SELECT title, year FROM album ORDER BY year',
    sub { $_->[1] < 1990 ? $_ : () },    # filter
    sub { split ' ', $_->[0] },          # flatMap
    sub {lc},                            # map
)->all;
say "@words";    # disraeli gears arrival
```

A stage can be a code reference, a [pipeline](#10-pipelines), or one
of Ekorn::Pipeline's stage objects, such as those its words and the
canned stages make. [How values go through
stages](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md#how-values-go-through-stages),
in Ekorn's reference, has the details.

### Context

DBIx::Squirrel::Context's functions tell a stage what it can't work
out from its value. None is exported by default.

<!-- not run -->
```perl
use DBIx::Squirrel::Context qw(iterator result_number result_original);
```

| Function | Returns |
|---|---|
| `iterator` | The iterator running the stage, in its own stages. Its `sth` is the statement handle, and the statement handle's `Database` is the database handle. |
| `result_number` | The number of the result being made, from 1. It counts results, not rows. While a stage drops rows, the number stays the same. Each value a stage returns in place of one row is a result of its own. In a flush, it's the number of the first value the flush returns. |
| `result_original` | The row the result is being made from, as it was fetched, before any stage changed it. For a result set, it's the row object. In a [flush](#7-gathering-stages-made-for-each-run), and the stages after it, it's `undef`: what a flush gives comes from every row, not one. |

`result_original` works in any run reading a statement: an iterator's
or result set's own stages, and the stages of a chain made with `|`,
or of a pipeline of yours, reading one, as it's read from the [run's
context](#the-runs-context). `result_number` and `iterator` work only
in an iterator's or result set's own stages, run by its `next`, `all`,
`first` or `single`, or by a sink given last to the call that made it.
Elsewhere, and outside a stage, they return `undef`.

```perl
my @chart = $dbh->iterate(
    'SELECT name, plays FROM track ORDER BY plays DESC',
    sub { $_->[0] },
    sub { result_number() . ". $_ (" . result_original()->[1] . ')' },
)->all;
say $chart[0];    # 1. Dancing Queen (9100)
```

### Canned stages

Four modules of ready-made stages ship with DBIx::Squirrel, each for
one kind of job. Each exports the stages it's usually used for, and
the rest on request. `:all` gives them all, and `()` none. Naming a
stage in the import list replaces the defaults. To have the defaults
and one more, name `:DEFAULT` too:

<!-- not run -->
```perl
use DBIx::Squirrel::Stages::Flow qw(:DEFAULT take_while);
```

| Module | Exported by default | On request |
|---|---|---|
| `DBIx::Squirrel::Stages::Flow` | `take($n)`, `drop($n)` | `take_first`, `take_last`, `take_single`, `take_while { ... }`, `drop_while { ... }`, `take_if { ... }`, `drop_if { ... }` |
| `DBIx::Squirrel::Stages::Rows` | `pluck($column)`, `as_hash` | |
| `DBIx::Squirrel::Stages::Batch` | `batch($n)`, `collect`, `collect { ... }` | |
| `DBIx::Squirrel::Stages::Taps` | `peek { ... }`, `count_into(\$n)` | `dump_to($fh)` |

Flow's are described in [6. Stopping a
pipeline](#6-stopping-a-pipeline), and Batch's in [7.
Gathering](#7-gathering-stages-made-for-each-run). Flow's, Batch's and
Taps' stages are Ekorn::Pipeline's, exported from a list of
DBIx::Squirrel's own; its reference's [Canned
stages](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md#canned-stages)
describes them in full. Rows' stages are DBIx::Squirrel's own. Each is
a function that makes a stage, checking what it's given when it's
called, not on each value.

| Stage | What it does |
|---|---|
| `pluck($column)` | Gives one column of each row, by its name, in any case, or its position, from 0, whether the row is an array, a hash or a row object. |
| `as_hash` | Gives each row as a hash, as `fetchrow_hashref` would, keyed as `FetchHashKeyName` says. A hash row is passed on unchanged. |
| `peek { ... }` | Calls the block with each value, and passes the value on. |
| `count_into(\$n)` | Counts the values into `$n`, from 0 on each run, and passes them on. |
| `dump_to($fh)` | Writes each value, with Data::Dumper, to `$fh` or STDERR, and passes it on. |

```perl
my $read  = 0;
my @names = $dbh->iterate(
    'SELECT id, name FROM artist ORDER BY id',
    count_into(\$read),
    pluck('name'),
)->all;
say "@names, from $read rows";    # Abba Blur Cream, from 3 rows

my $album = $dbh->iterate('SELECT title, year FROM album WHERE id = 2', as_hash)->first;
say "$album->{title} ($album->{year})";    # Parklife (1994)
```

`pluck` and `as_hash` find the column names in the [run's
context](#the-runs-context), which a statement gives it: an iterator's
or result set's own stages, or a chain made with `|`, or a pipeline of
yours, reading one. So a name for an array row, or `as_hash`, needs a
statement to be what the run reads. `pluck` by name for a hash row
reads the hash's own keys, and works anywhere.

**`pluck` reads the statement's columns, not the row's.** After a
stage that reshapes rows, a name or position for an array row picks
the wrong field, and says nothing. Make the rows hashes first, with
`as_hash`. Then `pluck` by name reads each hash's own keys:

```perl
my $sql = 'SELECT id, name FROM artist ORDER BY id';

my @wrong = $dbh->iterate(
    $sql,
    sub { [reverse @$_] },
    pluck('id'),
)->all;
say "@wrong";    # Abba Blur Cream

my @ids = $dbh->iterate(
    $sql,
    as_hash,
    sub { +{%$_, name => uc $_->{name}} },
    pluck('id'),
)->all;
say "@ids";    # 1 2 3
```

`dump_to` is for debugging. It writes each value in full, secrets and
all. It doesn't escape control characters in strings, so a value from
outside can send escape sequences to a terminal.

## 6. Stopping a pipeline

The user guide's [chapter 6](HOWTO.md#6-stopping-early).

### Stop

<!-- not run -->
```perl
use DBIx::Squirrel::Stop;

Stop();
Stop(@values);
Ekorn::Pipeline::Stop->throw(@values);
```

Called from a stage, `Stop` ends the run early and quietly:

- The rest of that stage doesn't run.
- The values already out of the pipeline are kept.
- Any values the stop carries go on through the stages after it.
- Nothing else is processed, and no more rows are fetched.

An iterator that's stopped finishes its statement. Stages after the
one that stopped, made with
[`gather`](#7-gathering-stages-made-for-each-run), still have their
flushes called.

```perl
my @upto = $dbh->iterate(
    'SELECT title, year FROM album ORDER BY year',
    sub { $_->[1] >= 1990 ? Stop($_) : $_ },    # this one, then no more
    sub { $_->[0] },
)->all;
say "@upto";    # Disraeli Gears Arrival Parklife
```

`Stop` is exported by default. `Ekorn::Pipeline::Stop->throw(@values)`
does the same without importing it. To keep `Stop` out of your
namespace, `use DBIx::Squirrel::Stop ()`.

### What a stop is

A stop is an exception, an `Ekorn::Pipeline::Stop`, which the pipeline
catches. DBIx::Squirrel::Stop isn't a class: it exports Ekorn's
`Stop`. A subclass of your own is a subclass of
`Ekorn::Pipeline::Stop`, and stops a pipeline as `Stop` does. Ekorn's
reference says what a stop holds, in [The stop
object](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md#the-stop-object).

A stage that catches errors itself, with `eval` or `try`, should throw
a stop on again. Check for `Ekorn::Pipeline::Stop`. Every stop is one,
including those the canned stages throw, such as `take`'s:

```perl
use experimental qw(try);

my @safe = $dbh->iterate(
    'SELECT name FROM artist ORDER BY id',
    sub ($row) {
        try {
            Stop() if $row->[0] eq 'Cream';
            return uc $row->[0];
        }
        catch ($e) {
            die $e if $e isa 'Ekorn::Pipeline::Stop';
            return 'unknown';
        }
    },
)->all;
say "@safe";    # ABBA BLUR
```

### Taking and dropping

DBIx::Squirrel::Stages::Flow's stages decide which values go on, by
their place or by a test:

| Stage | What it does |
|---|---|
| `take($n)` | Passes on the first `$n` values, then stops the run, so no more rows are fetched. |
| `drop($n)` | Drops the first `$n` values, and passes on the rest. |
| `take_first` | Passes on the first value, then stops the run: `take(1)`. |
| `take_last` | Passes on the last value, once there are no more, reading every one to find it; nothing if there were none. |
| `take_single` | Passes on the one value. At a second, it warns, `Expected only one item, but there were more`, and stops the run, so only the first goes on. |
| `take_while { ... }` | Passes on values while the block is true of them. At the first it's false of, it stops the run, and doesn't pass that value on. |
| `drop_while { ... }` | Drops values while the block is true of them, then passes on the rest, from the first it's false of. |
| `take_if { ... }` | Passes on each value the block is true of, testing every one, as `grep` does; it never stops the run. |
| `drop_if { ... }` | Passes on each value the block is false of, testing every one. |

```perl
my @page = $dbh->iterate(
    'SELECT name FROM track ORDER BY id',
    sub { $_->[0] },
    drop(2),
    take(2),
)->all;
say join ', ', @page;    # Girls & Boys, Parklife

my @hits = $dbh->iterate(
    'SELECT name, plays FROM track ORDER BY plays DESC',
    take_while { $_->[1] > 6000 },
    sub { $_->[0] },
)->all;
say join ', ', @hits;    # Dancing Queen, Sunshine of Your Love, Girls & Boys

my @newest = $dbh->iterate(
    'SELECT title FROM album ORDER BY year',
    take_last,
    sub { $_->[0] },
)->all;
say "@newest";    # The Great Escape

my @popular = $dbh->iterate(
    'SELECT name, plays FROM track ORDER BY id',
    take_if { $_->[1] > 6000 },
    sub { $_->[0] },
)->all;
say join ', ', @popular;    # Dancing Queen, Girls & Boys, Sunshine of Your Love
```

In SQL, `LIMIT` and `OFFSET` page results in the database, which is
quicker. `take` and `drop` are for when a stage in Perl decides which
rows go on.

## 7. Gathering: stages made for each run

The user guide's [chapter 7](HOWTO.md#7-parts-made-for-each-run).

### gather

<!-- not run -->
```perl
use DBIx::Squirrel::Gather;

my $stage = gather { ...; return $step };
my $stage = gather { ...; return ($step, $flush) };
my $stage = gather { ...; return ($step, $flush, $end) };
my $stage = gather { ...; return {step => $step, flush => $flush, end => $end} };
```

`gather` makes a stage afresh at the start of each run, by calling its
block, so whatever the block declares is fresh each time. A run is
each execution of an iterator or result set, including after `reset`,
each call of a Sugar statement, and each call of a pipeline. The block
returns:

- **the step:** a code reference, called with each value as any stage
  is, or a pipeline, whose stages are made for the run in its place;
- **optionally, the flush:** called with no arguments once the values
  run out, even if there were none. What it returns goes through the
  rest of the stages, as what a stage returns does. After a
  [stop](#6-stopping-a-pipeline), only the flushes of the stages after
  the one that stopped are called;
- **optionally, the end:** called once the run has ended, however it
  ended, and told how: `done`, `stopped` or `died`. An iterator's run
  is `done` once its rows run out, and `stopped` when `first` or
  `single` finishes it. What the end returns is dropped.

The parts can be given as a list, in that order, with `undef` for a
flush left out before an end, or by name, as one hash reference with
the keys `step`, `flush` and `end`, giving only those the stage has.

```perl
# Each value, then, once they run out, how many there were
sub and_count () {
    return gather {
        my $count = 0;    # this run's
        return (sub ($value) { $count++; $value }, sub () {"($count)"});
    };
}

my $it = $dbh->iterate(
    'SELECT name FROM artist ORDER BY id',
    sub { $_->[0] },
    and_count,
);
say join ' ', $it->all;           # Abba Blur Cream (3)
say join ' ', $it->reset->all;    # Abba Blur Cream (3)

my @how;
my $watched = gather { +{step => sub { $_->[0] }, end => sub ($how) { push @how, $how }} };
$dbh->iterate('SELECT name FROM artist', $watched)->first;
say "@how";    # stopped
```

A block that returns anything else croaks as the run starts:
`Expected stage #%s, made with gather, to return a code reference or a pipeline, and optionally a flush and an end`.
`gather` given something other than a block or code reference croaks
`Expected a code reference`. Ekorn's reference gives the order flushes
and ends are called in, in [Flushes and
ends](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md#flushes-and-ends).

A stage made with `gather` is an `Ekorn::Pipeline::Gather`, an object
that can go wherever a stage can. `gather` is exported by default; to
keep it out of your namespace, `use DBIx::Squirrel::Gather ()`.

### Batching and collecting

DBIx::Squirrel::Stages::Batch's stages are made with `gather`:

| Stage | What it does |
|---|---|
| `batch($n)` | Passes values on in batches of `$n`, each an array. The last, shorter batch comes when the values run out. |
| `collect` | Holds every value. When they run out, it passes on an array of them. |
| `collect { ... }` | Holds every value. When they run out, it passes on what the block makes of them, given as its arguments. |

```perl
my @batches = $dbh->iterate(
    'SELECT name FROM track ORDER BY id',
    pluck('name'),
    batch(4),
)->all;
say scalar(@$_), ': ', join ', ', @$_ for @batches;
# 4: Dancing Queen, Knowing Me, Knowing You, Girls & Boys, Parklife
# 2: Country House, Sunshine of Your Love

say $dbh->iterate(
    'SELECT name FROM artist ORDER BY id',
    pluck('name'),
    collect { join '+', @_ },
)->first;
# Abba+Blur+Cream

```

## 8. Sinks

The user guide's [chapter
8](HOWTO.md#8-sinks-saying-what-you-want-back).

A sink is a last stage that says what a run gives. Given last to
`iterate`, `results`, a Sugar function, or a select method, it makes
the call read the run through and give the sink's result, not an
iterator. The sinks are Ekorn::Pipeline's, from
Ekorn::Pipeline::Sinks, which exports none by default, and
DBIx::Squirrel::Tooling's `:sinks` exports them all:

<!-- not run -->
```perl
use Ekorn::Pipeline::Sinks qw(keep_all keep_first keep_last keep_single keep count_items to_file to_fh);
```

| Sink | Gives | Stops the run early? |
|---|---|---|
| `keep_all` | every result, as a list; or, where one value is asked for, an array reference of them | no |
| `keep_first` | the first result, or `undef` if none | yes |
| `keep_last` | the last result, reading every one to find it, or `undef` if none | no |
| `keep_single` | the one result, or `undef` if none; at a second, a warning, `Expected only one item, but there were more`, and the first | at a second |
| `keep($n)` | the first `$n` results, as a list, or an array reference where one value is asked for | yes, at `$n` |
| `count_items` | how many results there were | no |
| `to_file($path)` | writes each result to the file, a line each, and gives how many; it closes the file however the run ends | no |
| `to_fh($fh)` | prints each result to your filehandle, a line each, and gives how many; you close it | no |

A sink of many, `keep_all` or `keep`, never gives a count: for that,
use `count_items`. An empty result is an empty array reference, which
is true, so test it with `@$rows`.

```perl
my @names = $dbh->iterate(
    'SELECT name FROM artist ORDER BY id',
    pluck('name'),
    keep_all,
);
my $names = $dbh->iterate(
    'SELECT name FROM artist ORDER BY id',
    pluck('name'),
    keep_all,
);
say "@names";            # Abba Blur Cream
say scalar @$names;      # 3

say $dbh->iterate(
    'SELECT name FROM track ORDER BY plays',
    pluck('name'),
    keep_last,
);
# Dancing Queen

say $dbh->iterate(
    'SELECT name FROM artist WHERE id = ?', 2,
    pluck('name'),
    keep_single,
);
# Blur

say join ', ', $dbh->iterate(
    'SELECT name FROM track ORDER BY plays DESC',
    pluck('name'),
    keep(2),
);
# Dancing Queen, Sunshine of Your Love

say $dbh->iterate('SELECT * FROM album', count_items);    # 4
```

The iterator's methods and the sinks overlap: `all` and `keep_all`,
`first` and `keep_first`, `single` and `keep_single`. A method takes
what's left of an iterator you have; a sink says, in the call, what it
gives, and is the only way to have a count, the last, the first few,
or a file. `all` without stages is quicker than `keep_all`, as it
fetches every row in one go.

Ekorn's reference has the sinks in full, and how to write one, in
[Sinks](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md#sinks-ekornpipelinesinks).

## 9. Result sets and row objects

The user guide's [chapter 9](HOWTO.md#9-rows-as-objects).

### results

<!-- not run -->
```perl
$results = $dbh->results($statement, \%attr, @bind_values, @stages);
$results = $dbh->results($statement, @bind_values, @stages);
$results = $sth->results(@bind_values, @stages);
@result  = $dbh->results($statement, @bind_values, @stages, $sink);
```

As [`iterate`](#iterate), returning a `DBIx::Squirrel::Results`, or a
sink's result, if the last stage is a sink. A result set is an
iterator whose rows are objects, with a method for each column, named
in lower case. The stages see the objects. A result set has the
iterator's methods, and no others.

```perl
my $results = $dbh->results('SELECT id, Name FROM artist WHERE id <= ? ORDER BY id', 2);
while (my($artist) = $results->next) {
    say $artist->id, ' ', $artist->name;
}
# 1 Abba
# 2 Blur
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

- if its name can't be a method's, such as `COUNT(*)`;
- if the base class already has a method of that name, such as `can`,
  `isa`, `get_column`, or one of your own.

When two columns have one name, as in `SELECT a.id, b.id`, the method
is the first's. To give such a column a method, give it another name
in the statement, with `AS`:

```perl
my $row = $dbh->results('SELECT COUNT(*), COUNT(*) AS albums FROM album')->first;
say $row->albums;    # 4
say $row->[0];       # 4
```

### get_column

<!-- not run -->
```perl
$value = $row->get_column($name);
$value = $row->get_column($position);
```

Returns a column's value by its name, in any case, or by its position,
from 0. It reaches every column, including those without a method. It
croaks if the row has no such column:
`Expected a column of the row (x)`.

```perl
my $row = $dbh->results('SELECT COUNT(*) FROM album')->first;
say $row->get_column('count(*)');    # 4
say $row->get_column(0);             # 4
```

### Methods of your own

Row classes are subclasses of `DBIx::Squirrel::Result`, or of the
class given in the `ekorn_result_class` attribute, which must itself
be a subclass of `DBIx::Squirrel::Result`. So rows can have methods of
your own:

```perl
package My::Artist {
    our @ISA = 'DBIx::Squirrel::Result';
    sub shout ($self) { return uc $self->name }
}

my $artist = $dbh->results('SELECT * FROM artist WHERE id = 2', {ekorn_result_class => 'My::Artist'})->first;
say $artist->shout;    # BLUR
```

A class that isn't a subclass of `DBIx::Squirrel::Result` croaks:
`Expected ekorn_result_class to be a subclass of DBIx::Squirrel::Result (My::Other)`.

## 10. Pipelines

The user guide's [chapter
10](HOWTO.md#10-building-pipelines-from-pipelines).

The pipeline is
[Ekorn::Pipeline](https://github.com/nukopian/Ekorn-Pipeline)'s. It
began here, and is now a distribution of its own, so that any function
can take stages from its caller. DBIx::Squirrel uses it as it is: a
pipeline is made with `Ekorn::Pipeline->new`, and the handles' `pipe`
and `tap` are Ekorn::Pipeline::Pipes'. Loading it doesn't load the
DBI, so a pipeline works in code that has nothing to do with a
database.

DBIx::Squirrel keeps its own names for the modules of functions:
`DBIx::Squirrel::Stop`, `DBIx::Squirrel::Gather`, and the stages in
`DBIx::Squirrel::Stages::Flow`, `Batch` and `Taps`. Each exports
Ekorn's functions from a list of DBIx::Squirrel's own, so a function
added to Ekorn::Pipeline reaches DBIx::Squirrel's modules only once
it's added to that list, and documented here. The objects are Ekorn's:
a stop is an `Ekorn::Pipeline::Stop`, and a stage made with `gather`
an `Ekorn::Pipeline::Gather`. DBIx::Squirrel subclasses none of
Ekorn's classes.

Ekorn::Pipeline's
[reference](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md)
describes the pipeline in full, and its [user
guide](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/HOWTO.md)
has recipes for any values. This chapter keeps to what DBIx::Squirrel
does with it.

### Making and running a pipeline

<!-- not run -->
```perl
use Ekorn::Pipeline;

my $p       = Ekorn::Pipeline->new(@stages);
my @results = $p->(@values);              # push: values in, a list out
my $next    = $p->iterator($source);      # pull: one value per call
my @stages  = $p->stages;
```

A pipeline is an object that can be called as a code reference. Called
with values, it returns what comes out of the last stage: every value
in list context; in scalar context, a sink's result, if a sink is
last, or how many values came out. `iterator` returns an iterator, an
object called as a code reference, handing out those values one per
call, from a source; a DBIx::Squirrel iterator is a source ([15.
Protocols](#the-iterator-as-a-source)). `stages` returns the
pipeline's stages, in order, a pipeline given as a stage appearing as
the stages it was made of.

```perl
use Ekorn::Pipeline;

my $shout = Ekorn::Pipeline->new(
    sub {uc},
    sub {"$_!"},
);
say join ' ', $shout->('hello', 'world');    # HELLO! WORLD!

my $next  = Ekorn::Pipeline->new(sub { $_->[0] })->iterator($dbh->iterate('SELECT name FROM artist ORDER BY id'));
my @names;
while (my($name) = $next->()) { push @names, $name }
say "@names";    # Abba Blur Cream
```

### A pipeline as a stage

A pipeline can go wherever a stage goes: in another pipeline, or given
to `iterate`, `results`, an iterator's `reset`, `pipe`, `tap`, a
select method, or a Sugar function, for a database or a statement. Its
stages run in its place, as if written out there, so a `take` inside
it limits the whole run:

```perl
use Ekorn::Pipeline;

my $hits = Ekorn::Pipeline->new(
    sub { $_->[1] >= 5000 ? $_ : () },
    pluck('name'),
);
my $sql  = 'SELECT name, plays FROM track ORDER BY plays DESC';
say join ', ', $dbh->iterate($sql, $hits)->all;             # Dancing Queen, Sunshine of Your Love, Girls & Boys, Parklife
say join ', ', $dbh->iterate(
    $sql,
    $hits,
    take(1),
)->all;
# Dancing Queen

```

Make a stage that counts or remembers with
[`gather`](#7-gathering-stages-made-for-each-run). A plain closure is
the same code reference wherever it goes, so its state is shared by
every run it's in.

### Named pipelines

<!-- not run -->
```perl
Ekorn::Pipeline->named($name => @stages);
use Ekorn::Pipeline::Factories qw(pipeline);
my $p = pipeline($name, @more_stages);
```

`Ekorn::Pipeline->named` names a pipeline for the rest of the program,
in the package that names it, unless the name is qualified, as
`My::Module::clean`. `pipeline`, from Ekorn::Pipeline::Factories,
makes a pipeline of stages and names, looked up in its caller's
package as it's made. A name given alone gives the pipeline named, so
its stages are numbered where it stands. The [Sugar's
definitions](#statement) take names too. Ekorn's reference has the
rules, in [Named
pipelines](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md#named-pipelines).

```perl
use Ekorn::Pipeline;

Ekorn::Pipeline->named(first_column => sub { $_->[0] });
say join ' ', $dbh->iterate('SELECT name FROM artist ORDER BY id', pipeline('first_column', take(2)))->all;    # Abba Blur
```

### pipe and tap

<!-- not run -->
```perl
@results = $dbh->pipe(@stages);
$result  = $dbh->pipe(@stages);
$dbh     = $dbh->tap(@stages);
```

Database and statement handles both have these methods, from
Ekorn::Pipeline::Pipes. `pipe` runs the handle itself through stages,
and returns what comes out of the last one: all of it in list context;
in scalar context, the first value, or `undef`. With no stages, it
returns the handle. `tap` runs the handle through stages for their
side effects, drops what comes out, and returns the handle however
they end, so a chain of method calls can carry on. On a statement
handle, the statement handle goes through the stages instead.

```perl
my @names = $dbh->pipe(
    sub ($dbh) { @{ $dbh->selectcol_arrayref('SELECT name FROM artist ORDER BY id') } },
    sub {uc},
);
say "@names";    # ABBA BLUR CREAM

my $n = $dbh->tap(sub ($dbh) { say 'tapped ', ref $dbh })->selectrow_array('SELECT COUNT(*) FROM artist');
say $n;
# tapped DBIx::Squirrel::db
# 3
```

[pipe and
tap](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md#pipe-and-tap-ekornpipelinepipes),
in Ekorn's reference, says how to give a class of your own the same.

### When a stage dies

If a stage dies, the call that asked for the result croaks, at your
line. The message names the stage by its place, from `#1`, and indents
the stage's own message below. A stage inside a pipeline given as a
stage is named by its place in each: `#2.3` is the third stage of the
pipeline given as stage #2. A stage of a named pipeline gives the name
and its place there too: `#2.2 (main::fussy#2)`. An exception object
is passed on unchanged.

```perl
my $it = $dbh->iterate(
    'SELECT name FROM artist',
    sub {$_},
    sub { die "no names today\n" },
);
eval { $it->next };
print $@;
# Pipeline stage #2 failed at ... line ...:
#     no names today

say $it->ended;    # died
say scalar(() = $it->next);    # 0
```

Once a stage dies, its run has ended. An iterator then returns nothing
more: `next` returns an empty list on every call after, and `all`
returns nothing. No more rows are fetched, no flush is called, and the
statement is finished. An end is still called, told `died`. `reset`
runs the statement again, from the start. To pass over a value a stage
can't handle, the stage catches its own error and returns nothing for
it, as [What a stop is](#what-a-stop-is) shows.

## 11. Operators: | and @{}

The user guide's [chapter 11](HOWTO.md#11-chaining-with--and-).

<!-- not run -->
```perl
use Ekorn::Pipeline::Operators;

$result = $it | @stages... | $sink;
$chain  = $it | $stage;
@values = @$it;
```

An iterator, and so a result set, overloads `|` and `@{}` with
Ekorn::Pipeline::Operators' `chain` and `drain`, as Ekorn's own
sources do. They're in force only where
`use Ekorn::Pipeline::Operators` is in scope. Elsewhere, both croak:
`Expected use Ekorn::Pipeline::Operators in scope, for |`.
DBIx::Squirrel loads Operators with an empty import list, so it's
there, but in force only where you say.

- `$it | $stage` gives a chain: the iterator's results through the
  stage, which `|` can extend, and which is a source.
- `$it | ... | $sink` gives the sink's result.
- `@$it`, or `@{ $chain }`, gives every result.

**`|` always gives one value.** Perl calls an operator for one value,
so a chain ending in `keep_all` gives an array reference, even
assigned to an array: `my @rows = $it | keep_all` has one element. Use
`@{ $it | keep_all }`, or give the stages and sink to `iterate` as
arguments.

**Each use is a run of its own,** from the first row, through the
iterator's stages. So `$it->[0]`, `scalar @$it` and `$#$it` read every
row to give one row, a count or an index; two uses run the statement
twice; and `for (@$it)` reads every row before the loop starts.

**The run it starts is the iterator's.** It ends a run the iterator
had going, so `next` returns nothing after, and `ended` says how the
`|` or `@{}` run ended, until `reset`.

```perl
use Ekorn::Pipeline::Operators;

my $it    = $dbh->iterate('SELECT name FROM artist ORDER BY id', pluck('name'));
my $names = $it | keep_all;
say "@$names";                  # Abba Blur Cream
say $it | count_items;          # 3
say "@$it";                     # Abba Blur Cream
say "@{ $it | sub {lc} }";      # abba blur cream

my @one = $it | keep_all;
say scalar @one;                # 1
```

A chain run only for its sink's effect, written as a statement of its
own, runs, but Perl warns "Useless use of numeric bitwise or (|) in
void context" as it compiles the line, before any operator is called.
Keep the result: `my $n = $it | to_file($path)`.

## 12. Sugar: a function for each database and statement

The user guide's [chapter
12](HOWTO.md#12-a-function-for-each-database-and-statement).

`DBIx::Squirrel::Sugar` gives each database a name. The package that
names it gets a function of that name, which returns the database
handle or runs a statement on it. A statement gets a function too,
which runs it with the bind values and any stages given.

### Defining them on use

<!-- not run -->
```perl
use DBIx::Squirrel::Sugar database => {
    music => [$data_source, $username, $password, \%attr],
};
use DBIx::Squirrel::Sugar statement => {
    artist_names => [music => 'SELECT name FROM artist', sub ($row) { $row->[0] }],
    artist       => [music => 'SELECT * FROM artist WHERE id = :id'],
};
use DBIx::Squirrel::Sugar qw(database statement);
```

Given a hash reference after `database` or `statement`, `use` defines
each database or statement named in it, with its arguments in an array
reference. It gives the package each function while the package is
compiled, so the function can be called without parentheses. The
arguments are worked out then too: the environment, literals, and what
a `BEGIN` block has set are there, but a variable the program sets as
it runs is not yet. `use` also gives the package the `database` and
`statement` functions, and, given just their names, only those.

### database

<!-- not run -->
```perl
$dbh      = database($name);
$function = database($name, @connect_args);
```

Given a name, returns the handle of the database defined by that name,
anywhere in the program, connecting to it if it isn't connected. Given
a name and the arguments `connect` takes, it defines a database by
that name, gives the calling package a function of that name, and
returns the function. A database defined with a database handle, in
place of a data source, is a clone of it, as `connect` makes, made
when the database is first used. A database is defined once in a
program, by a name that can be a function's, which the package hasn't
a function of already.

### The function a database is given

<!-- not run -->
```perl
$dbh     = music();
$sth     = music($statement, @bind_values);
$sth     = music($statement, \%attr, @bind_values);
$it      = music($statement, @bind_values, @stages);
@results = music($statement, @bind_values, @stages, $sink);
```

| Called with | It |
|---|---|
| nothing | returns the database handle. |
| a statement and bind values | prepares the statement, executes it, and returns the statement handle, or nothing if it couldn't be executed. |
| those, and stages at the end | returns what `iterate` does: an iterator over the results, or, if the last stage is a sink, the sink's result. |

A hash reference or `undef` straight after the statement is the
attributes to prepare it with. The statement can be a statement
handle, which is itself executed, or iterated over.

```perl
use DBIx::Squirrel::Sugar database => {music => ['dbi:SQLite:dbname=music.db', '', '', {RaiseError => 1}]};

say music('SELECT name FROM artist WHERE id = ?', 1)->fetchrow_arrayref->[0];    # Abba
say ref music('SELECT name FROM artist', sub { $_->[0] });                        # DBIx::Squirrel::Iterator
say join ' ', music(
    'SELECT name FROM artist ORDER BY id',
    sub { $_->[0] },
    keep_all,
);
# Abba Blur Cream

```

### statement

<!-- not run -->
```perl
$function = statement($name, $database, $statement, @stages);
$function = statement($name, $database, $statement, \%attr, @stages);
```

Defines a statement by that name, on the database of that name. The
attributes are those to prepare it with, and the stages are its own.
It gives the calling package a function of that name, and returns the
function. The database is found when the function runs, so it can be
defined after the statement.

A stage in a definition can be a pipeline's **name**, as
Ekorn::Pipeline names them with `named`: words joined by `::`. A name
is looked up as the statement is defined, in the package defining it,
unless it's qualified, as `My::Module::clean`, and stands in its place
among the stages. So it must be defined first, and one that isn't
croaks then: `No pipeline named main::clean`. On `use`, the definition
is made as the program compiles, so define the name in a `BEGIN` block
before it.

### The function a statement is given

<!-- not run -->
```perl
$sth     = artist(@bind_values);
$it      = artist(@bind_values, @stages);
@results = artist(@bind_values, @stages, $sink);
```

It executes the statement with the bind values, and returns the
statement handle, or nothing if it couldn't be executed. With stages,
its own or those given after the bind values, it returns an iterator
over the results, or, if the last stage is a sink, the sink's result,
as `iterate` does. The results go through its own stages, then those
given. Stages given are for that call only. A string given is always a
bind value, never a pipeline's name.

```perl
use Ekorn::Pipeline;

BEGIN { Ekorn::Pipeline->named(shouted => sub {uc}) }

use DBIx::Squirrel::Sugar statement => {
    artist_names => [music => 'SELECT name FROM artist ORDER BY id', sub { $_->[0] }],
    loud_names   => [music => 'SELECT name FROM artist ORDER BY id', sub { $_->[0] }, 'shouted'],
    artist       => [music => 'SELECT * FROM artist WHERE id = :id'],
};

say ref artist_names;                            # DBIx::Squirrel::Iterator
say join ' ', artist_names keep_all;             # Abba Blur Cream
say join ' ', artist_names sub {lc}, keep_all;   # abba blur cream
say artist_names count_items;                    # 3
say join ' ', loud_names keep_all;               # ABBA BLUR CREAM
say artist(id => 3)->fetchrow_hashref->{name};   # Cream
```

A sink, imported, is a function of your package, so a statement can't
be given its name: `Expected no function of the name in main already
(count_items)`. With Tooling's `:all`, that's any name it exports.
Import fewer tags, or by name, or call one by its full name,
`Ekorn::Pipeline::Sinks::count_items()`.

The statement is prepared once for each database handle, with
`prepare_cached`. Its handle may be in use: by a statement handle not
read to the end, or by an iterator of an earlier call still reading. A
call then prepares one of its own. A statement taking a [list](#lists)
is prepared for each call's values instead, and isn't cached.

## 13. Caching and connections

The user guide's [chapter 13](HOWTO.md#13-caching-and-connections).

### prepare_cached

<!-- not run -->
```perl
$sth = $dbh->prepare_cached($statement);
$sth = $dbh->prepare_cached($statement, \%attr);
$sth = $dbh->prepare_cached($statement, \%attr, $if_active);
```

As `prepare`, using the DBI's cache of statement handles. Its errors
name `prepare_cached`, as the DBI's do. Like `prepare`, it croaks
given a statement taking a [list](#lists).

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

```perl
my $sql   = 'SELECT name FROM artist ORDER BY id';
my $first = $dbh->prepare_cached($sql)->iterate(sub { $_->[0] });
$first->next;
my $second = $dbh->prepare_cached($sql)->iterate(sub { $_->[0] });
say $first->sth == $second->sth ? 'shared' : 'a handle each';    # a handle each
say join ' ', $second->all;    # Abba Blur Cream
say join ' ', $first->all;     # Blur Cream
```

### connect_cached

`connect_cached` is the DBI's own. It calls `connect` when it needs a
new connection, so it croaks on failure too. DBIx::Squirrel's own
attributes are part of the cache's key. Two calls with the same
attributes have the same handle, and calls with different ones don't.

### The Sugar's connections

A Sugar database is connected to when it's first used, not when it's
defined, with `connect_cached`. So two databases defined with the same
arguments share a handle. The handle is kept, and each use has the
same one, without a ping to the database each time. It's pinged only
while its last call has failed, which leaves the error to be read.
It's made again if the connection has gone, or if the handle has been
disconnected. So the call after a connection drops fails, as it would
with plain DBI, and the call after that has a new connection.

## 14. Writing stages, and functions that take them

The user guide's [chapter
14](HOWTO.md#14-functions-that-take-stages-and-stages-for-others).

### A function that takes stages

A function can take stages from its caller, at the end of its
arguments, and hand them to `iterate` after its values. Its caller
then gets an iterator, or, with a sink last, the sink's result. To
find the stages at the end of a list of arguments, test each from the
end with Ekorn::Pipeline's `is_stage`, which is true of code
references, pipelines and Ekorn's stage objects, and false of strings
and other values:

```perl
use Ekorn::Pipeline qw(is_stage);

sub albums_since ($year, @stages) {
    return $dbh->iterate('SELECT title FROM album WHERE year >= ? ORDER BY year', $year, @stages);
}

say albums_since(1990, count_items);    # 2
say is_stage(sub {1}) ? 'a stage' : 'a value';    # a stage
say is_stage('name') ? 'a stage' : 'a value';     # a value
```

### Stages for others

A stage of your own is a code reference, or a pipeline of other
stages. Ekorn's reference, in [Writing
stages](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md#writing-stages),
and its user guide, in [Building parts for
others](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/HOWTO.md#10-building-parts-for-others),
say how to write one that works alongside the canned stages:

- a function that makes it, checking its options once;
- state in a `gather` block, so it starts afresh on each run;
- a flush, for a stage that holds values, and an end, for one that
  holds something to release;
- `Stop`, for one that knows no more are wanted;
- a tap that returns the value it was given;
- names, exports and tests.

What follows is what's particular to stages for rows.

**The shapes of a row.** A row can be an array, a hash (with the
`ekorn_slice` attribute), or a row object (from `results`). A stage
for others should say which it takes, or take all three, as `pluck`
does. A stage that needs the statement's column names reads them from
the [run's context](#the-runs-context).

**Errors.** A function that makes a stage croaks when it's given the
wrong things, so the message names the line that called it. A module
of stages sets its `@CARP_NOT` to DBIx::Squirrel's internal packages,
which take in the DBI's and Ekorn::Pipeline's. Then what it croaks
while a row goes through its stage is reported at the line that asked
for the result, not inside DBIx::Squirrel:

```perl
package My::Stages {
    use DBIx::Squirrel::Errors qw(croakf);

    our @CARP_NOT = @DBIx::Squirrel::Errors::INTERNAL;

    sub prefixed ($prefix) {
        croakf 'Expected a prefix' unless defined $prefix && length $prefix;
        return sub ($value) {"$prefix$value"};
    }
}

say join ' ', $dbh->iterate(
    'SELECT name FROM artist ORDER BY id',
    sub { $_->[0] },
    My::Stages::prefixed('#'),
)->all;
# #Abba #Blur #Cream

eval { My::Stages::prefixed('') };
print $@;    # Expected a prefix at ... line ...
```

`croakf` croaks with a message made by `sprintf`. Its format is a
literal, written in the code, with the values as its arguments. Never
make the format from data: it does whatever its `%` directives say.

**Where they go.** A stage goes where what it needs to know is. One
that needs a database, a statement, a row's column names, or the row a
result came from goes under `DBIx::Squirrel::Stages::`. One that would
work on values from anywhere belongs under
`Ekorn::Pipeline::Stages::`, where any function's stages can use it,
even if it was written for rows. Ekorn::Pipeline can't depend on
DBIx::Squirrel, so a stage that would `use` DBIx::Squirrel goes under
`DBIx::Squirrel::Stages::`. A stage added under
`Ekorn::Pipeline::Stages::` reaches DBIx::Squirrel's users only once
DBIx::Squirrel adds it to the names its own modules of stages export.
The user guide's [Decide where a stage
belongs](HOWTO.md#decide-where-a-stage-belongs) says how to choose.

**Testing.** A pipeline called with values tests a stage without a
database. Run it twice, to show it starts afresh. Then run it on rows
from an in-memory SQLite database, in each shape it takes.

**Publishing.** Name a module of stages for its job, as
`DBIx::Squirrel::Stages::JSON`, in a distribution named
`DBIx-Squirrel-Stages-JSON`. Have it require the DBIx::Squirrel it was
tested with: v3.0.0 is the first with sinks, `|` and the run's context
described in [15. Protocols](#15-protocols).

## 15. Protocols

What other code can rely on: the contracts between DBIx::Squirrel and
Ekorn::Pipeline, and between a statement's run and the stages reading
it. They're Ekorn::Pipeline's protocols, as DBIx::Squirrel keeps them;
Ekorn's reference describes the protocols themselves, in [Delivering
parts for
Ekorn](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md#delivering-parts-for-ekorn).

### The iterator as a source

A `DBIx::Squirrel::Iterator`, and so a result set, is a source, as
Ekorn::Pipeline takes one: it offers `EKORN_SOURCE`, the role method a
pipeline's `iterator`, a chain made with `|` and `@{}` call. You don't
call it yourself. Each call starts a fresh run of the statement, from
its first row:

- the statement is executed again, finishing it first if it's active,
  as `reset` does, with the iterator's bind values;
- the rows go through the iterator's own stages before they leave it,
  so a pipeline reading it gets its results, not its rows;
- the run's context is the statement's (see below);
- the run is the iterator's: one it had going ends, and `ended` says
  how this one ended;
- if another iterator over the same statement handle has results left,
  it croaks, `Expected the statement handle's other iterator to be
  finished`, rather than take the handle from under it.

A run reading the iterator reads on even if the iterator itself is let
go first, and finishes the statement when it ends.

```perl
use Ekorn::Pipeline;

my $it   = $dbh->iterate('SELECT name FROM artist ORDER BY id', sub { $_->[0] });
my $next = Ekorn::Pipeline->new(sub {uc})->iterator($it);
undef $it;
my @names;
while (my($name) = $next->()) { push @names, $name }
say "@names";    # ABBA BLUR CREAM
```

### The run's context

A run reading a statement, whether the iterator's own or a pipeline's
reading it, has the statement's context, which a stage asks for with
`Ekorn::Pipeline::run_context()`. It's a hash reference:

| Key | Value |
|---|---|
| `statement` | The statement handle, a `DBIx::Squirrel::st`. |
| `columns` | A reference to an array of the statement's column names, as `fetchrow_hashref` keys them, following `FetchHashKeyName`, read when the statement was executed. |
| `row` | The row the statement gave last, as fetched, or as a row object for a result set: the row the value a stage is working on came from. `undef` once the run has ended. |

A run whose context has a `statement` that's a `DBIx::Squirrel::st` is
reading a statement; any other run, such as a pipeline called with
values, has some other context, or none. `pluck`, `as_hash` and
`result_original` read it, and so can a stage of yours. While a flush
gives its values, which come from every row, not one,
`Ekorn::Pipeline::ending()` is true, and the row is no value's;
`result_original` gives `undef` then.

```perl
my $columns = sub ($row) {
    my $context = Ekorn::Pipeline::run_context();
    return join ', ', map {"$_=$row->[$_ eq 'id' ? 0 : 1]"} @{ $context->{columns} };
};
say join '; ', $dbh->iterate('SELECT id, name FROM artist ORDER BY id', $columns)->all;    # id=1, name=Abba; id=2, name=Blur; id=3, name=Cream
```

The context is the run's: a pipeline called inside a stage has its
own, which has no row unless it too reads a statement.

### What a call takes as stages

`iterate`, `results`, an iterator's `reset`, the select methods,
`pipe`, `tap` and the Sugar's functions take as stages, at the end of
their arguments, whatever Ekorn::Pipeline's `is_stage` is true of:
code references, pipelines, and Ekorn's stage objects, among them
stages made with `gather`, Ekorn's words and the canned stages, and
its sinks. Anything else is a bind value, so an object of your own
given as a value stays one. A sink, if one is last, says what the call
gives (see [8. Sinks](#8-sinks)). Only a Sugar statement's definition
takes pipelines' names, as strings.

### What a gather's block returns

A `gather` block, Ekorn's protocol for a part made for each run,
returns its step, flush and end, as a list or by name in a hash
reference (see [gather](#gather)). DBIx::Squirrel adds nothing to it;
Ekorn's reference has it in full, in
[gather](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md#gather).

## 16. Errors and diagnostics

The user guide's [chapter 15](HOWTO.md#15-when-things-go-wrong).

### Errors

Errors are reported at the line of your code that called
DBIx::Squirrel, never at a line inside it or the DBI. That includes
the DBI's own errors under `RaiseError`, such as
`DBD::SQLite::db prepare failed: near "SELEC": syntax error`, which
keep the DBI's message.

DBIx::Squirrel croaks where the DBI would return `undef` in `connect`,
`prepare` and `prepare_cached`. The error then has the message the DBI
raises under `RaiseError`, so it reads the same whatever `RaiseError`
is set to.

Each error names the method you called, as plain DBI does: `do` and
the select methods, not the `prepare` or `execute` they call;
`selectall_array`'s errors name `selectall_arrayref`, as the DBI's do.

An error from a `HandleError` callback, or one that isn't a string, is
passed on unchanged. The DBI's warnings, under `PrintError`, its
default, are reported the same way plain DBI reports them: at your
line, naming the method you called.

```perl
eval { $dbh->prepare('SELEC name FROM artist') };
print $@;    # DBD::SQLite::db prepare failed: near "SELEC": syntax error at ... line ...
```

### Diagnostics

These are DBIx::Squirrel's own messages, and the messages of
Ekorn::Pipeline's that its users meet. Each is reported at the
caller's line. Those starting "Expected" say what was expected.

#### Connecting, preparing and binding

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

#### Iterators and result sets

| Message | Cause |
|---|---|
| `Expected a statement handle` | `DBIx::Squirrel::Iterator->new` wasn't given a `DBIx::Squirrel::st`. |
| `Expected only one item, but there were more` | A warning: `single`, `keep_single` or `take_single` found a second result, and gave the first. |
| `Expected the statement handle's other iterator to be finished` | Another iterator over the same statement handle has results left. |
| `Expected ekorn_result_class to be a subclass of DBIx::Squirrel::Result (%s)` | `ekorn_result_class` named a class that isn't one. |
| `Expected a column of the row (%s)` | `get_column` or `pluck` was given a name or position the row doesn't have. |
| `Expected use Ekorn::Pipeline::Operators in scope, for %s` | `\|` or `@{}` was used on an iterator where the operators aren't in force. |

#### Pipelines

| Message | Cause |
|---|---|
| `Expected stage #%d to be a code reference or a pipeline` | Something passed as a stage to a pipeline, `pipe` or `tap` wasn't one. No stage runs. |
| `Expected a code reference` | The block given to `gather`, `take_while`, `drop_while`, `take_if`, `drop_if`, `collect` or `peek`, or the source given to a pipeline's `iterator`, wasn't a code reference. |
| `Expected stage #%s, made with gather, to return a code reference or a pipeline, and optionally a flush and an end` | The block given to `gather` for that stage returned something else. |
| `Pipeline stage #%s failed at %s line %d:` | A stage, or its flush, died. The message it died with follows, indented. See [When a stage dies](#when-a-stage-dies). |
| `Pipeline end of stage #%s failed at %s line %d:` | A stage's end died, in a run that hadn't died already. |
| `Stop used outside a pipeline` | `Stop` was called where no pipeline was running to catch it. |
| `No pipeline named %s` | A name, in a Sugar statement's definition or given to `pipeline`, has no pipeline. |

#### Canned stages and sinks

| Message | Cause |
|---|---|
| `Expected a count of 0 or more` | `take`, `drop` or `keep` was given something other than a whole number. |
| `Expected a batch size of 1 or more` | `batch` was given something other than a whole number above 0. |
| `Expected a column, by name or position` | `pluck` was given no column, or an empty name. |
| `Expected an iterator, for the column names` | `as_hash`, or `pluck` with a name for an array row or a position for a hash row, ran where no statement was being read, such as in a pipeline called with values. |
| `Expected a row: an array, a hash or a row object` | `pluck` or `as_hash` was given a value that isn't a row. |
| `Expected a reference to a scalar` | `count_into` was given something else. |
| `Expected an open filehandle` | `dump_to` or `to_fh` was given something else. |

#### Sugar

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
| `Expected only code references, pipelines or their names after the statement for %s` | A statement's definition had something other than stages, which are code references, pipelines or pipelines' names, after the statement and its attributes. |
| `Expected no function of the name in %s already (%s)` | The package has a function of that name already, such as a sink it imported. |

## Differences from plain DBI

Where DBIx::Squirrel and plain DBI do the same thing, they give the
same result. These are the places they differ.

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
| Stages after the select methods' values | None. | What the DBI gives is pushed through them. |
| Iterators, result sets, pipelines | None. | `iterate`, `results`, sinks, `\|` and `@{}`, `pipe`, `tap` and the Sugar. |

## Upgrading from 2.x

Version 3 builds on Ekorn::Pipeline v0.3.0, and makes one rule of what
a call gives: a statement is a source; DBIx::Squirrel's calls give an
iterator, and only a sink given last turns it into a result. These are
the changes code written for 2.x meets, and how to move:

| Your code | What happens now | How to move |
|---|---|---|
| A Sugar statement given stages, read as a list: `my @names = artist_names sub {...}` | gives an iterator, not every result | give a sink last: `artist_names sub {...}, keep_all` |
| A Sugar statement given stages in scalar context, for a count | gives an iterator | give `count_items` last |
| `$it->count` | fails: the method is gone | give `count_items` last, or count as you go with `count_into(\$n)` |
| `my $n = $it->all`, for a count | an array reference | `count_items` given last |
| `$it->single`, after `next` | the next result, not a fresh run's only one | `$it->reset->single` |
| `$it->single`, at a second result | a warning, and the first, not a croak | check for the warning, or keep the croak with a stage of your own |
| `DBIx::Squirrel::Pipeline->new(...)` | fails: the module is gone | `Ekorn::Pipeline->new(...)`, or `pipeline(...)` from Ekorn::Pipeline::Factories |
| `$x isa 'DBIx::Squirrel::Pipeline'` | false | `$x isa 'Ekorn::Pipeline'` |
| `DBIx::Squirrel::Stop->throw`, or a subclass of DBIx::Squirrel::Stop | fails: it's no longer a class | `Ekorn::Pipeline::Stop->throw`, and subclass `Ekorn::Pipeline::Stop` |
| `ref $stage eq 'CODE'`, or `is_coderef($stage)`, for a stage made by `take`, `gather` and the like | false: they're objects now, called as code references | `is_stage($stage)`, from Ekorn::Pipeline |
| A `gather` block's second part, "the end function" | the same, now called the flush | nothing; an end, told how the run ended, can follow it |
| `result_number` or `iterator` in a pipeline of your own reading an iterator | `undef` | count in a stage of your own |
| `my($first) = $sth->iterate->next`, then using the handle | the handle is finished once the iterator goes | keep the iterator while the handle is in use |

Everything else works as it did: `iterate`, `results`, and the select
methods and Sugar without stages or a sink last, `pluck`, `as_hash`,
`take`, `Stop`, and `gather`. New: `first`, `ended`, sinks given last,
`|` and `@{}`, stages for the select methods, named pipelines in the
Sugar's definitions, and the run's context as a documented protocol.

## Upgrading from 1.x

DBIx::Squirrel 2 was a rewrite, not an update, and version 3 builds on
it. Code written for 1.x needs changes before it runs. The ideas carry
over, so most changes are a rename or a simpler call. But some methods
keep their names and change what they do. They're marked **in bold**
below.

To stay on 1.x, which supports Perl 5.10.1 and later, install the last
version by its number:

```
cpanm DBIx::Squirrel@1.6.5
```

### Requirements and loading

| 1.x | Now |
|---|---|
| Perl 5.10.1 or later. | Perl 5.36 or later. |
| Hard dependencies on Compress::Bzip2, Crypt::CBC, Dotenv, JSON::Syck, YAML::Syck and others. | DBI, Ekorn::Pipeline, Ref::Util, namespace::clean, and a few core modules. |
| Loading it read a `.env` file in the current directory, through Dotenv. | Nothing is read. Load your environment yourself. |

### Importing and the entity helpers

| 1.x | Now |
|---|---|
| `use DBIx::Squirrel database_entities => [qw(db artists)];` | `use DBIx::Squirrel::Sugar database => {...}, statement => {...};` |
| A helper was associated at run time: `db(DBIx::Squirrel->connect(...))`. | A database is defined by the arguments to connect with, and connected when first used: `database => {db => [$dsn, $user, $pass]}`. |
| A helper could hold a database, a statement or an iterator. | A function holds a database, or a statement on a database by name, with stages of its own. |
| A helper for a result set returned the iterator, so `artist('Aerosmith')->single->ArtistId`. | A statement's function returns the statement handle, or, with stages, an iterator, or a sink's result: `artist('Aerosmith', sub ($row) { $row->[0] }, keep_single)`. |

<!-- not run -->
```perl
# 1.x
use DBIx::Squirrel database_entities => [qw(db artist)];
db(DBIx::Squirrel->connect($dsn, $user, $pass));
artist(db->results('SELECT * FROM artists WHERE Name = ? LIMIT 1'));
say artist('Aerosmith')->single->ArtistId;

# Now
use DBIx::Squirrel::Sugar
    database  => {db => [$ENV{DSN}, $ENV{USER}, $ENV{PASS}]},
    statement => {artist_id => [db => 'SELECT ArtistId FROM artists WHERE Name = ?', sub ($row) { $row->[0] }]};
use Ekorn::Pipeline::Sinks qw(keep_single);
my $id = artist_id('Aerosmith', keep_single);
```

### Placeholders and binding

| 1.x | Now |
|---|---|
| `?`, `?1`, `:1`, `$1` and `:name`. | The same, and `$name`. |
| Placeholders were found anywhere in the statement: in quoted strings, and in casts, so `x::int` broke. | Not in quoted strings, comments, casts or PostgreSQL's dollar-quoted bodies, read by the database's rules. See [What isn't a placeholder](#what-isnt-a-placeholder). |
| Styles could be mixed. | One style to a statement. A mix croaks. |
| `--` comments were removed before the statement reached the database. | Comments are passed on to the database. |

Binding by name, as pairs or in a hash reference, with or without the
sigil, works as it did.

### do

| 1.x | Now |
|---|---|
| **In list context, `do` returned the row count and the statement handle.** | `do` returns what the DBI's returns, in any context. Use `prepare` and `execute` for the handle. |

### Iterator and result set methods

| 1.x | Now |
|---|---|
| `it` and `iterator`, aliases of `iterate`. | `iterate` only. |
| `rs` and `resultset`, aliases of `results`. | `results` only. |
| `$dbh->iterate($sql, [@bind_values, @transforms])`: values and stages in one array reference. | Stages are at the end of the arguments: `$dbh->iterate($sql, @bind_values, @stages)`. |
| **`next` put the result in `$_`**, as in `while ($it->next) { say $_->Name }`. | Nothing is put in `$_`: `while (my($row) = $it->next) { say $row->name }`. |
| `all` in scalar context returned a reference to the results. | The same. |
| **`count` fetched the rest of the results and returned how many there were in all.** | Gone: give `count_items` last, as `$dbh->iterate($sql, count_items)`. |
| `count_fetched`. | Gone: `count_into(\$n)` as a stage, or `result_number` in one. |
| `single` and `one` returned the first result, with a warning if there were more. | `single` the same; `one` is gone. |
| `first`. | The same. |
| `last` and `last_fetched`. | Gone: `keep_last` given last, or `take_last` as a stage. |
| `remaining`. | `all`, which returns the results not yet handed out. |
| `start` and `iterate` on an iterator, to execute it with new bind values. | `reset(@bind_values, @stages)`. |
| `reset($slice, $cache_size)`, to change the slice or the cache size. | `reset` takes bind values and stages. The slice is the `ekorn_slice` attribute. Rows are fetched 2 at first, up to 64 at a time. |
| `slice`, `cache_size` and their package-wide defaults, `$DBIx::Squirrel::it::DEFAULT_SLICE` among them. | The `ekorn_slice` attribute, on `connect` or `prepare`. |
| `is_active`, `not_active` and `rows`. | Gone: `$it->sth->{Active}` and `$it->sth->rows`. |

### Rows as objects

| 1.x | Now |
|---|---|
| **A column's method matched its name in any case:** `$row->ArtistId` or `$row->artistid`. | Methods are named in lower case only: `$row->artistid`. |
| Methods were made the first time each was called. | A class with a method for each column is made for each list of columns. See [Row objects](#row-objects). |
| A column whose name can't be a method's, such as `COUNT(*)`, was reached by its position. | By its position still, as rows are arrays, or with `get_column`, or given a name with `AS`. |

### Transformations, now stages

The stages work as transformations did. Each gets a value as its
argument and in `$_`, and returns nothing to drop it, one value, or
several. These have changed:

| 1.x | Now |
|---|---|
| `use DBIx::Squirrel::it qw(...)`, for what a stage can ask. | `use DBIx::Squirrel::Context qw(...)`. |
| `iterator`, `result_number` and `result_original`. | The same, from DBIx::Squirrel::Context. |
| `database` and `statement`. | `iterator->sth->{Database}` and `iterator->sth`, or the [run's context](#the-runs-context). |
| `result` and `result_current`. | The stage's argument. |
| `result_first`, `result_prev`, `result_previous` and `result_offset`. | Gone. A stage that needs them keeps them itself, in a [`gather`](#gather) block. |
| `DBIx::Squirrel::Transform::Data::Dumper`'s `as_perl`, and `DBIx::Squirrel::Transform::IO`'s `stdout` and `stderr`. | `dump_to` and `peek`, from DBIx::Squirrel::Stages::Taps. See [Canned stages](#canned-stages). |
| No way to end a transformation early. | `Stop`, from DBIx::Squirrel::Stop. See [Stop](#stop). |

### Gone, out of scope

These have no place now. Any that come back will come back as
distributions of their own.

| 1.x | Instead |
|---|---|
| `DBIx::Squirrel::Crypt::Fernet`, and `decrypt` from DBIx::Squirrel::util. | A Fernet module from CPAN. |
| `DBIx::Squirrel::Transform::JSON::Syck` and `DBIx::Squirrel::Transform::YAML::Syck`. | A stage of your own calling a JSON or YAML module. See [Stages for others](#stages-for-others). |
| `get_file_contents`, `slurp`, `uncompress`, `unmarshal` and `utf8decode`, from DBIx::Squirrel::util. | Path::Tiny, IO::Uncompress::Bunzip2, a JSON module, and Encode. |
| `load_tuples`, on a database handle. | `prepare` and `execute`, in a loop. |
| `statement_digest`, `statement_normalise`, `statement_study` and `statement_trim`, on a statement handle. | `study_sql` and `trim_sql`, from DBIx::Squirrel::Placeholders. |

## The modules

| Module | What it is |
|---|---|
| `DBIx::Squirrel` | The class you connect with; a subclass of `DBI`. |
| `DBIx::Squirrel::db` | The database handle class; a subclass of `DBI::db`, with Ekorn::Pipeline::Pipes' `pipe` and `tap`. |
| `DBIx::Squirrel::st` | The statement handle class; a subclass of `DBI::st`, with `pipe` and `tap` too. |
| `DBIx::Squirrel::Iterator` | An iterator over a statement's results, and a source for Ekorn::Pipeline. |
| `DBIx::Squirrel::Results` | An iterator handing out rows as objects. |
| `DBIx::Squirrel::Result` | The base class of row objects. Its `class_for`, which makes the row classes, is internal. |
| `DBIx::Squirrel::Stop` | Exports Ekorn::Pipeline's `Stop`, which ends a pipeline early. |
| `DBIx::Squirrel::Gather` | Exports Ekorn::Pipeline's `gather`, which makes a stage afresh for each run. |
| `DBIx::Squirrel::Stages::Flow` | Canned stages taking or dropping values: `take`, `drop`, `take_first`, `take_last`, `take_single`, `take_while`, `drop_while`, `take_if`, `drop_if`. |
| `DBIx::Squirrel::Stages::Rows` | Canned stages reshaping rows: `pluck`, `as_hash`. |
| `DBIx::Squirrel::Stages::Batch` | Canned stages gathering values: `batch`, `collect`. |
| `DBIx::Squirrel::Stages::Taps` | Canned stages run for their side effects: `peek`, `count_into`, `dump_to`. |
| `DBIx::Squirrel::Context` | What a stage can ask about the result it's making. Its `within` and `statement_context` are internal, for the iterators and the stages for rows. |
| `DBIx::Squirrel::Tooling` | Exports what callers use to do work, from one place, by tags: see [Importing](#importing-dbixsquirreltooling). |
| `DBIx::Squirrel::Sugar` | A function for each database and statement. |
| `DBIx::Squirrel::Placeholders` | Finds the placeholders in a statement, and matches values to them. Internal: `trim_sql`, `study_sql`, `key_of`, `is_numbered`, `values_taken`, `values_for`, `expand_lists` and `place_values` are for the handles. |
| `DBIx::Squirrel::Errors` | Reports errors at the caller's line. Internal, apart from `croakf` and `@INTERNAL`, which a module of stages uses: `at_caller`, `in_method` and `failed` are for the handles. See [Stages for others](#stages-for-others). |
| `DBIx::Squirrel::Util` | Helpers the modules share: `canonical`, `install_sub`, `is_name`, `iterator_going`, `shift_attrs`, `split_attrs`, `split_stages` and `unwrap_values`. Internal: they may change without notice. |
| `DBIx::Squirrel::Manual::Reference` and `DBIx::Squirrel::Manual::HowTo` | This reference and the user guide, as POD, for MetaCPAN. |

Pipelines, the operators and the sinks are Ekorn::Pipeline's own:
`Ekorn::Pipeline`, `Ekorn::Pipeline::Operators`,
`Ekorn::Pipeline::Sinks` and `Ekorn::Pipeline::Factories`.
