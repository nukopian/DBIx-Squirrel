# DBIx::Squirrel reference

<!-- stopwords: bitwise flatMap -->

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
- [Making each kind of part](#making-each-kind-of-part)
- [Differences from plain DBI](#differences-from-plain-dbi)
- [Upgrading from 2.x](#upgrading-from-2x)
- [Upgrading from 1.x](#upgrading-from-1x)
- [Index](#index)

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

# Stages beside the query, for what SQL can't do, and a sink last to
# say what comes back: the two most played tracks not yet on a phone
my %on_my_phone = map { $_ => 1 } 'Dancing Queen', 'Parklife', 'Sunshine of Your Love';
my @next = $dbh->iterate(
    'SELECT name FROM track ORDER BY plays DESC',
    pluck('name'),
    drop_if { $on_my_phone{$_} },
    take(2),
    keep_all,
);
say join ', ', @next;    # Girls & Boys, Knowing Me, Knowing You

# The words in the tracks' names
say $dbh->iterate('SELECT name FROM track', sub { split ' ', $_->[0] }, count_items);    # 16

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
| `:taps` | `peek`, `count_into`, `dump_to`, `tee` | [Stages::Taps](#canned-stages) |
| `:rows` | `pluck`, `as_hash` | [Stages::Rows](#canned-stages) |
| `:stages` | `:flow`, `:batch`, `:taps` and `:rows` | |
| `:context` | `iterator`, `result_number`, `result_original` | [Context](#context) |
| `:sources` | `from_array`, `from_fh`, `from_file`, `counter` | Ekorn::Pipeline::Sources |
| `:sinks` | `count_items`, `keep`, `keep_all`, `keep_first`, `keep_last`, `keep_single`, `to_fh`, `to_file` | [Sinks](#8-sinks) |
| `:json` | `from_json`, `from_jsonl`, `to_json`, `to_jsonl` | Ekorn::Pipeline::JSON |
| `:csv` | `from_csv`, `to_csv` | Ekorn::Pipeline::CSV |
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
- **JSON.pm's names.** JSON exports a `from_json` and a `to_json` of
  its own, by default, so a module using both imports `:all` or `:json`
  from only one of them, or calls the other's by its full name.
- **Text::CSV.** `:csv`'s names need it, but load it only when one
  is first called, so `:csv` and `:all` import without it.
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

A program connects with `DBIx::Squirrel->connect` where it would call
`DBI->connect`, and everything after works as it did: the handles are
subclasses of the DBI's, `DBIx::Squirrel::db` and `DBIx::Squirrel::st`,
so they do everything the DBI's handles do. For SQLite, or any data
source without a username or password, the attributes can follow the
data source straight away, as in [the examples'
database](#the-examples-database).

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
  value or `undef` in place of a list. So does a list holding an
  unblessed reference, such as `[[1, 2, 3]]` to a statement whose one
  value is a list. An object in a list is a value.
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

A statement, with placeholders in any of the [styles](#the-styles),
can be written in whichever of four ways suits where it comes from:

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

Binding values apart from executing suits a statement run more than
once, or values gathered before it runs. As `bind` returns the
statement handle, `execute` can follow it in the same line:

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

An object is a value, as it is to the DBI, whatever it's made of: a
blessed array isn't unwrapped, and a blessed hash isn't taken for
the attributes.

There are two exceptions, each for a statement taking one value:

- To a statement whose one value is a [list](#lists), the array
  reference is the list.
- DBD::Pg binds an array reference as a PostgreSQL array. So, with
  DBD::Pg, an array reference given to a statement taking one value,
  such as `SELECT * FROM artist WHERE id = ANY(?)`, is that value, as
  it would be with the DBI. Through another driver, such as DBD::ODBC,
  it's unwrapped as usual, as the driver can't bind arrays.

### bind_param

`bind_param` binds one value, with the DBI's attributes or type, which
`bind` and `execute` can't give. Its placeholder can be named in
whichever way suits its style:

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

### execute_array

`execute_array` and `execute_for_fetch` execute a statement once for
each row of values, as the DBI's do, and `bind_param_array` binds an
array of values to a placeholder, a value for each row. They're how
the DBI loads many rows at once. Plain DBI's work for `?`, and for
other styles only as far as the driver reads them; here they work for
every style:

- A row's values come in the order of its placeholders: by number, or,
  for names, in the order each first appears. `:id, :name, :id` takes
  two values a row, not three.
- For named placeholders, a row can be a hash, keyed by name, with or
  without the sigil: rows shaped by [as_hash](#as_hash), or records
  from anywhere, load as they are.
- `bind_param_array` names its placeholder as
  [`bind_param`](#bind_param) does: by number or by name, with or
  without the sigil. A plain value, not an array, is the value for
  every row.

```perl
$dbh->do('CREATE TEMP TABLE gig (artist TEXT, city TEXT, year INTEGER)');
my $sth = $dbh->prepare('INSERT INTO gig (artist, city, year) VALUES (:artist, :city, :year)');

# An array for each name, in the order each first appears
say scalar $sth->execute_array({}, ['Abba', 'Blur'], ['Brighton', 'Colchester'], [1974, 1990]);    # 2

# Rows as hashes, from anything that gives them
my @rows = ({artist => 'Cream', city => 'Windsor', year => 1966});
say scalar $sth->execute_for_fetch(sub { shift @rows });    # 1

# Arrays bound by name, and a value for every row
$sth->bind_param_array(':artist', ['Abba', 'Cream']);
$sth->bind_param_array(city => ['London', 'London']);
$sth->bind_param_array(year => 1977);
my @status;
say scalar $sth->execute_array({ArrayTupleStatus => \@status});    # 2
say "@status";                                                     # 1 1

say $dbh->selectrow_array('SELECT COUNT(*) FROM gig');    # 5
$dbh->do('DROP TABLE gig');
```

`ArrayTupleFetch` and `ArrayTupleStatus` work as the DBI's do, and so
does context: in a list, `execute_array` gives the rows executed and
the rows changed. The counts the DBI checks are of the placeholders,
not their uses, and its errors are its own, raised as its
attributes say. A row of the wrong shape croaks at the caller's line,
as `execute` would. A statement with a [list](#lists) can't take
rows, as its handle is prepared for lists of one length: each of the
three croaks, `Expected no list placeholder in a statement for rows of
values (...:ids)`. Arrays bound with `bind_param_array` are kept with
the statement, not in the DBI's `ParamArrays`, for any style but `?`.

### do

Unlike the DBI's, the attributes may be left out. The first argument
after the statement is taken as the attributes only if it's an
unblessed hash reference or `undef`. An array reference there stands
for the [values in it](#an-array-reference-of-values). Any other
unblessed reference croaks: `Expected a reference to a HASH or ARRAY`.
An object there is a bind value, as it is to the DBI.

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

Each select method works as the DBI's does, given no stages. It
prepares the statement as `prepare` does, unless it's already a
statement handle, and binds the values as [`bind`](#bind) binds them,
so placeholders can be in any style. `selectall_hashref`'s key field
can be an array reference of fields, for nested keys, and
`selectcol_arrayref` takes the DBI's `Columns` attribute, as the DBI's
do:

```perl
my @row = $dbh->selectrow_array('SELECT id, name FROM artist WHERE id = ?', 2);
say "@row";    # 2 Blur

say $dbh->selectrow_hashref('SELECT * FROM artist WHERE id = :id', id => 1)->{name};    # Abba

my $col = $dbh->selectcol_arrayref('SELECT name FROM artist WHERE id IN ($1, $2) ORDER BY id', 1, 2);
say "@$col";    # Abba Blur

my $by_id = $dbh->selectall_hashref('SELECT id, name FROM artist', 'id');
say $by_id->{3}{name};    # Cream
```

As with [`do`](#do), the attributes may be left out. The first
argument after the statement, or after `selectall_hashref`'s key
field, is taken as the attributes only if it's an unblessed hash
reference or `undef`. So named values given in a hash reference, or a
first value that's `undef`, need the attributes, or `undef`, in front.

**Given stages after the bind values,** each pushes what the DBI's
method returns through them, as a pipeline called with values does. It
returns every value that comes out of the last. Where one value is
asked for, it returns a sink's result, if a sink is last, or else how
many values came out. As a pushed run has no statement as its source,
the stages can't use `pluck` by a name for an array row, or `as_hash`;
`pluck` with no column, or by position, works.

What goes through the stages is what the method returns.
`selectall_array` returns the rows, so each row goes through on its
own, and `selectrow_array` each of the row's values. The others return
one reference, so a stage gets all of it at once: every row, for
`selectall_arrayref`.

```perl
my @slugs = $dbh->selectall_array('SELECT title FROM album ORDER BY year', pluck, sub { lc s( \W+ )(-)xgr });
say "@slugs";    # disraeli-gears arrival parklife the-great-escape

say scalar $dbh->selectall_array('SELECT name FROM track', sub { split ' ', $_->[0] });    # 16

say join ',', $dbh->selectrow_array('SELECT id, name FROM artist WHERE id = :id', id => 2, sub {"<$_>"});    # <2>,<Blur>

say $dbh->selectall_arrayref('SELECT name FROM artist ORDER BY id', sub { join ' ', map { $_->[0] } @$_ });    # Abba Blur Cream
```

`selectall_array` with stages is the select method most like
[`iterate`](#iterate), but every row is fetched before the first goes
through the stages. An iterator fetches rows as they're wanted, and
stops fetching when a stage stops the run.

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

An iterator is the usual way to read a statement's results here: it
fetches rows as they're wanted, and hands out each after it has run
through the stages. The bind values are in any form `execute` takes,
and, as with `do`, the attributes may be left out. The **stages** are
at the end of the arguments: code references, pipelines, or any of
Ekorn::Pipeline's stages. Each row is run through them, in order. See
[Stages](#stages).

**A sink given last says what comes back.** If the last stage is one
of Ekorn::Pipeline's [sinks](#8-sinks), `iterate` reads the run to its
end and returns the sink's result, not an iterator.

```perl
my $it = $dbh->iterate('SELECT name FROM artist WHERE name LIKE :pattern ORDER BY id', pattern => '%r%', pluck);
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
time a fetch fills its batch, up to 64. Past 64, each fetch's cost is
spread so thin that a bigger batch reads hardly any faster, and holds
more of a wide row's data. So reading one row fetches no more than
two, and DBIx::Squirrel holds no more than 64 rows of a result.

The driver may hold more. DBD::SQLite reads rows as they're fetched,
but DBD::Pg and DBD::mysql receive the whole result when the
statement is executed. With MySQL, the `mysql_use_result` attribute
makes the driver read rows as they're fetched. With PostgreSQL, a
cursor does, declared and fetched from in your SQL.

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

An iterator is read a result at a time with `next`, in a `while` loop,
or for what's left of the run, with `all`, or for one result, with
`first` or `single`. `all`, `first` and `single` take what's left of
the run, so after `next` they start from the next result, and each
finishes the statement, so the rest of its rows aren't fetched:

```perl
my $it = $dbh->iterate('SELECT name FROM artist ORDER BY id', pluck);
my($abba) = $it->next;
say $abba;                   # Abba
say join ' ', $it->all;      # Blur Cream

my $names = $dbh->iterate('SELECT name FROM artist ORDER BY id', pluck)->all;
say scalar @$names;          # 3

say $dbh->iterate('SELECT name FROM artist ORDER BY id', pluck)->first;                # Abba
say $dbh->iterate('SELECT name FROM artist WHERE id > 9', pluck)->first // 'none';    # none
say $dbh->iterate('SELECT COUNT(*) FROM track', pluck)->single;                        # 6
```

`single` is for a statement meant to give one result: if there's
another, it warns, and returns the first, which finds a statement that
lost its `LIMIT 1`, or its `WHERE`.

A stage can return `undef` as a result. So read `next` in list
context, as below, rather than testing whether what it returns is
defined. Once a stage dies, the iterator has ended: `next` returns an
empty list on every call after, and the statement is finished, until
[reset](#reset) runs it again.

```perl
my $it = $dbh->iterate('SELECT id, name FROM artist ORDER BY id', sub { $_->[0] == 2 ? undef : $_->[1] });
my @seen;
while (my($name) = $it->next) {
    push @seen, $name // '(none)';
}
say "@seen";    # Abba (none) Cream
```

`ended` tells how the last run ended: `done` when the rows ran out,
`stopped` when it was cut short, by `first`, by `single` finding a
second result, or by a stage that stopped, and `died` when a stage
died. It returns nothing while a run is going, or after `reset` starts
a new one. A run read with `|` or `@{}` is the iterator's last run too
(see [11. Operators](#11-operators--and-)).

```perl
my $it = $dbh->iterate('SELECT name FROM artist ORDER BY id', pluck);
$it->all;
say $it->ended;                   # done
$it->reset->first;
say $it->ended;                   # stopped
say $it->reset->ended // 'none';  # none
```

The iterator reaches its statement too. `column_names` gives the
statement's columns, as `fetchrow_hashref` would key them, executing
it first if it hasn't been. They're read when it's executed, as some
drivers, such as DBD::mysql, give none once the last row is fetched;
a stage asks for them through [iterator](#context). `sth` gives the
statement handle, which changes when `reset` prepares a statement
taking a [list](#lists) again, for a list of another length.

```perl
say join ', ', $dbh->iterate('SELECT id, title AS Album FROM album')->column_names;    # id, Album

my $it = $dbh->iterate('SELECT name FROM artist');
say $it->sth->{Statement};    # SELECT name FROM artist
```

`iterate` makes an iterator by calling `DBIx::Squirrel::Iterator->new`
with a statement handle, its bind values and stages. To iterate over a
handle you already have, call `iterate` on it, or `new` directly; a
handle that isn't DBIx::Squirrel's croaks, `Expected a DBIx::Squirrel
statement handle`.

```perl
my $sth = $dbh->prepare('SELECT name FROM artist WHERE id = ?');
say DBIx::Squirrel::Iterator->new($sth, 3, pluck)->first;    # Cream
```

### reset

One iterator can be read again, rather than made again: with other
bind values, which replace the ones before, or more stages, which join
its own, each kept until others are given. A run still going is
finished first, and whatever it held goes with it:

```perl
my $it = $dbh->iterate('SELECT name FROM artist WHERE id > ? ORDER BY id', 0, pluck);
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
my %little = map { $_ => 1 } qw(a of the);

my @words = $dbh->iterate(
    'SELECT title FROM album ORDER BY year',
    sub { split ' ', $_->[0] },       # flatMap
    sub {lc},                         # map
    sub { $little{$_} ? () : $_ },    # filter
)->all;
say "@words";    # disraeli gears arrival parklife great escape
```

The filter here tests words a stage made, which no `WHERE` can see. A
row the database could leave out, it should: a `WHERE` is quicker,
and fewer rows cross the wire.

A stage can be a code reference, a [pipeline](#10-pipelines), or one
of Ekorn::Pipeline's stage objects, such as those its words and the
canned stages make. [How values go through
stages](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md#how-values-go-through-stages),
in Ekorn's reference, has the details.

### Context

DBIx::Squirrel::Context's functions tell a stage what it can't work
out from its value: where in the results it is, the row its value came
from, and the iterator reading them. None is exported by default.

<!-- not run -->
```perl
use DBIx::Squirrel::Context qw(iterator result_number result_original);
```

`result_number` works in any run, as Ekorn::Pipeline counts every
run's results: an iterator's or result set's own stages, a chain made
with `|`, and a pipeline of yours, each counting its own.
`result_original` gives a statement's row in any run reading one,
chains included: it's Ekorn::Pipeline::Context's, and the statement's
source gives Ekorn the row as its original, which Ekorn passes through
chains. In a run reading no statement, it's the value the run's source
gave, or that was pushed.
`iterator` works only in an iterator's or result set's own stages, run
by its `next`, `all`, `first` or `single`, or by a sink given last to
the call that made it. Elsewhere it returns `undef`, and outside a run
all three do.

```perl
my @chart = $dbh->iterate(
    'SELECT name, plays FROM track ORDER BY plays DESC',
    sub { $_->[0] },
    sub { result_number() . ". $_ (" . result_original()->[1] . ')' },
)->all;
say $chart[0];    # 1. Dancing Queen (9100)
```

`result_number` counts results, not rows. While a stage drops rows,
the number stays the same, and each value a stage returns in place of
one row is a result of its own. So numbering after a filter numbers
what's left:

```perl
my %on_my_phone = map { $_ => 1 } 'Dancing Queen', 'Parklife', 'Sunshine of Your Love';

my @to_copy = $dbh->iterate(
    'SELECT name FROM track ORDER BY id',
    drop_if { $on_my_phone{ $_->[0] } },
    sub { result_number() . ". $_->[0]" },
)->all;
say for @to_copy;
# 1. Knowing Me, Knowing You
# 2. Girls & Boys
# 3. Country House
```

`result_original` keeps the row as it was fetched, so a stage after
others that reshaped it can still read any of its columns. For a
result set, it's the row object. In a flush of a stage made with
[gather](#gather), and the stages after it, it's `undef`, as what a
flush gives comes from every row, not one.

```perl
my @plays = $dbh->iterate(
    'SELECT name, plays FROM track ORDER BY plays DESC LIMIT 2',
    pluck('name'),
    sub { "$_: " . result_original()->[1] },
)->all;
say for @plays;
# Dancing Queen: 9100
# Sunshine of Your Love: 7700
```

`iterator` reaches the rest: its `sth` is the statement handle, the
statement handle's `Database` is the database handle, and its
`column_names` are the statement's columns.

```perl
my($columns) = $dbh->iterate(
    'SELECT id, name FROM artist WHERE id = 1',
    sub { join ',', iterator()->column_names },
)->all;
say $columns;                 # id,name
say iterator() // 'none';     # none
```

### Canned stages

Four modules of ready-made stages ship with DBIx::Squirrel, each for
one kind of job: Flow takes or drops values, Rows reshapes rows, Batch
gathers values together, and Taps looks at them as they go by. Each
exports the stages it's usually used for, and the rest upon request, as
the [index](#index) says. `:all` gives them all, and `()` none. Naming
a stage in the import list replaces the defaults. To have the defaults
and one more, name `:DEFAULT` too:

<!-- not run -->
```perl
use DBIx::Squirrel::Stages::Flow qw(:DEFAULT take_while);
```

Flow's are discussed in [Taking and dropping](#taking-and-dropping),
and Batch's in [Batching and collecting](#batching-and-collecting).
Flow's, Batch's and Taps' stages are Ekorn::Pipeline's, exported from
a list of DBIx::Squirrel's own; its reference's [Canned
stages](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md#canned-stages)
describes them too. Rows' stages are DBIx::Squirrel's own. Each is a
function that makes a stage, checking what it's given when it's
called, not on each value.

#### Reshaping rows

A row comes as an array, a hash (with the `ekorn_slice` attribute), or
a row object (from `results`), and `pluck` takes one column from any
of them: by name, in any case, or by position, from 0. Given no
column, it takes a row's only column, so a one-column query gives
plain values:

```perl
my @names = $dbh->iterate('SELECT id, name FROM artist ORDER BY id', pluck('name'))->all;
say "@names";    # Abba Blur Cream

say join ' ', $dbh->results('SELECT id, name FROM artist ORDER BY id', pluck(0))->all;    # 1 2 3
say join ' ', $dbh->iterate('SELECT name FROM artist ORDER BY id', pluck)->all;           # Abba Blur Cream
```

`pluck` with no column counts each row's own columns, and croaks at a
row of more than one, rather than give the first, which would go wrong
silently when a query gains a column. `pluck(0)` takes the first.

A name for an array row, or a position for a hash row, is found from
the statement's column names, in the [run's
context](#the-runs-context), once on each run: an iterator's or result
set's own stages, a chain made with `|`, or a pipeline of yours,
reading one. So it needs a statement to be what the run reads. A name
for a hash row reads the hash's own keys, so it works anywhere.

`as_hash` makes each row a hash, as `fetchrow_hashref` would, for code
written for the DBI's hashes:

```perl
my $album = $dbh->iterate('SELECT title, year FROM album WHERE id = 2', as_hash)->first;
say "$album->{title} ($album->{year})";    # Parklife (1994)
```

Given column names, `as_hash` keeps only those, so a stage after it,
or code given its hashes, gets the columns it needs, whatever the
`SELECT` gave. The names are found in any case, and the hash is keyed
as it would be without them. A name the row hasn't got croaks, so a
query that lost a column shows at once:

```perl
my @artists = $dbh->iterate('SELECT * FROM artist ORDER BY id LIMIT 2', as_hash('NAME'))->all;
say join ' ', keys %{ $artists[0] };              # name
say join ' ', map { $_->{name} } @artists;       # Abba Blur
```

The run's context still names every column the statement has, so a
stage reading it sees them all. `to_csv`'s `header => 1` is one: after
`as_hash` with names, give `to_csv` the same names as its header,
`header => [qw(name plays)]`, or it writes a column for each, empty
for those left out.

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

#### Taps

A tap looks at each value as it goes by and passes it on unchanged,
so a pipeline can be logged, counted or debugged without changing what
it gives. `peek` calls a block with each value; `count_into` counts
them into a variable, from 0 on each run:

```perl
my @seen;
my @names = $dbh->iterate(
    'SELECT name FROM artist ORDER BY id',
    pluck,
    peek { push @seen, length },
)->all;
say "@names: @seen";    # Abba Blur Cream: 4 4 5

my $read  = 0;
my @named = $dbh->iterate(
    'SELECT id, name FROM artist ORDER BY id',
    count_into(\$read),
    pluck('name'),
)->all;
say "@named, from $read rows";    # Abba Blur Cream, from 3 rows
```

`dump_to` is for debugging: it writes each value with Data::Dumper, to
a filehandle or STDERR. Where Text::Redact::Secrets v1.x is installed,
it writes each secret that module's rules find as `*REDACTED*`, in the
text it writes only: the value passed on is as it came. The rules find
a long, random password, token or key, such as the password in a DSN,
but not a short or ordinary password, so a dump can still hold
secrets. Without the module, or while
`local $Ekorn::Pipeline::Stages::Taps::DumpSecrets = 1` is set, it
writes each value in full; with the module there but broken, it
croaks rather than write a dump. It doesn't escape control characters
in strings, so a value from outside can send escape sequences to a
terminal.

```perl
open my $fh, '>', \my $dump or die $!;
$dbh->iterate('SELECT id, name FROM artist WHERE id = 1', as_hash, dump_to($fh))->all;
close $fh;
print $dump;
# {
#   'id' => 1,
#   'name' => 'Abba'
# }
```

Where a tap needs more than one thing done, `tee` runs each value
through a branch of stages of its own. The branch is a run beside the
main run: its stages keep their state across the values, a stop in it
ends only the branch, and a death in it kills the run. It shares the
main run's context, so `pluck` and `as_hash` work in it on a
statement's rows. Each value costs a push into the branch, several
times what `peek` costs, so it's for side jobs and debugging, not a
hot loop. A stop after the tee, such as `take`'s or `first`'s, closes
the branch, so its flushes run, and what it holds, such as a
part-filled `batch`, is handed on, as when the input runs out.

```perl
my @hits;
my @names = $dbh->iterate(
    'SELECT name, plays FROM track ORDER BY id',
    tee(take_if { $_->[1] > 6000 }, pluck('name'), sub { push @hits, $_; () }),
    pluck('name'),
)->all;
say scalar(@names), ' tracks; hits: ', join ', ', @hits;    # 6 tracks; hits: Dancing Queen, Girls & Boys, Sunshine of Your Love
```

## 6. Stopping a pipeline

The user guide's [chapter 6](HOWTO.md#6-stopping-early).

### Stop

A stage that knows no more results are wanted calls `Stop`, rather
than drop every row after, so no more rows are fetched. The run ends
early and quietly:

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
their place or by a test. In SQL, `LIMIT`, `OFFSET` and `WHERE` do
that in the database, which is quicker; these are for when Perl
decides: a test on data the database doesn't have, a test on what
came before, or a limit on what's left after one. A stage that stops
the run stops the fetching too, so no more rows are read than are
wanted. Some examples use a hash of the tracks already on a phone,
which the database knows nothing of.

**By place.** `take` and `drop` give a page: `drop(20), take(10)`
passes on values 21 to 30. `take` stops the run at its last
value, so the statement is finished then:

```perl
my %on_my_phone = map { $_ => 1 } 'Dancing Queen', 'Parklife', 'Sunshine of Your Love';

my @page = $dbh->iterate(
    'SELECT name FROM track ORDER BY id',
    pluck,
    drop_if { $on_my_phone{$_} },
    drop(1),
    take(2),
)->all;
say join ', ', @page;    # Girls & Boys, Country House
```

`take_first`, `take_last` and `take_single` each pass on one value,
and are the stages of the sinks `keep_first`, `keep_last` and
`keep_single`, so a pipeline can go on after them. `take_last` reads
every value to find the last. `take_single` is for a statement meant
to give one row: at a second, it warns and stops, so a forgotten
limit is found.

```perl
say $dbh->iterate('SELECT title FROM album ORDER BY year', pluck, take_first)->all;    # Disraeli Gears

my @newest = $dbh->iterate(
    'SELECT title FROM album ORDER BY year',
    take_last,
    pluck,
)->all;
say "@newest";    # The Great Escape

say $dbh->iterate('SELECT name FROM artist WHERE id = 2', pluck, take_single)->all;    # Blur
```

**By a test.** `take_if` and `drop_if` test every value, as `grep`
does, and never stop the run. A plain stage ending in a test passes on
what the test returns, true or false; `take_if` passes on the value:

```perl
my %on_my_phone = map { $_ => 1 } 'Dancing Queen', 'Parklife', 'Sunshine of Your Love';

my @copied = $dbh->iterate(
    'SELECT name FROM track ORDER BY id',
    take_if { $on_my_phone{ $_->[0] } },
    pluck(0),
)->all;
say join ', ', @copied;    # Dancing Queen, Parklife, Sunshine of Your Love

my @to_copy = $dbh->iterate(
    'SELECT name FROM track ORDER BY id',
    drop_if { $on_my_phone{ $_->[0] } },
    pluck(0),
)->all;
say join ', ', @to_copy;    # Knowing Me, Knowing You, Girls & Boys, Country House
```

A test the database could do, such as `plays > 6000`, belongs in the
`WHERE`. In a stage, it's for debugging: trying a condition on a
query's rows without touching the query, before it goes in the SQL:

```perl
my @would_keep = $dbh->iterate(
    'SELECT name, plays FROM track ORDER BY id',
    take_if { $_->[1] > 6000 },    # trying it out, before it goes in a WHERE
    pluck(0),
)->all;
say join ', ', @would_keep;    # Dancing Queen, Girls & Boys, Sunshine of Your Love
```

`take_while` and `drop_while` test values only until the first that
fails, so they suit rows in the order the test reads. `take_while`
stops the run there, and reads no further, where `take_if` would read
every row; `drop_while` passes on everything from there, without
testing again:

```perl
my $half   = $dbh->selectrow_array('SELECT SUM(plays) FROM track') / 2;
my $so_far = 0;

my @hits = $dbh->iterate(
    'SELECT name, plays FROM track ORDER BY plays DESC',
    take_while { $so_far < $half },    # the hits making half the plays
    sub { $so_far += $_->[1]; $_->[0] },
)->all;
say join ', ', @hits;    # Dancing Queen, Sunshine of Your Love, Girls & Boys

my $stopped_at = 'Arrival';    # where the last run stopped

my @still_to_do = $dbh->iterate(
    'SELECT title FROM album ORDER BY year',
    pluck,
    drop_while { $_ ne $stopped_at },
    drop(1),
)->all;
say join ', ', @still_to_do;    # Parklife, The Great Escape
```

## 7. Gathering: stages made for each run

The user guide's [chapter 7](HOWTO.md#7-parts-made-for-each-run).

### gather

A stage that keeps state, or holds values to give them together, is
made with `gather`, so its state starts afresh on each run: each
execution of an iterator or result set, including after `reset`, each
call of a Sugar statement, and each call of a pipeline. `gather` calls
its block at the start of each run, so whatever the block declares is
fresh each time. The block returns:

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
flush left out before an end. Or they can be given by name, in one
hash reference with the keys `step`, `flush` and `end`, giving only
those the stage has.

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
    pluck,
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

DBIx::Squirrel::Stages::Batch's stages hold values and pass them on
together. They're made with `gather`, so each run starts afresh, and
both pass on what they still hold once the values run out.

`batch` suits loading or sending rows in groups, as it holds no more
than one batch at a time; the last batch, given when the values run
out, may be shorter, and with no values there's no batch at all:

```perl
my @batches = $dbh->iterate(
    'SELECT name FROM track ORDER BY id',
    pluck('name'),
    batch(4),
)->all;
say scalar(@$_), ': ', join ', ', @$_ for @batches;
# 4: Dancing Queen, Knowing Me, Knowing You, Girls & Boys, Parklife
# 2: Country House, Sunshine of Your Love
```

`collect` holds every value until the end, so the whole result is in
memory at once. Given a block, it passes on what the block makes of
them all, which can be nothing, one value, or several; the block is
called even with no values, so `collect` always gives a result:

```perl
my($ids) = $dbh->iterate('SELECT id FROM artist ORDER BY id', pluck, collect)->all;
say "@$ids";    # 1 2 3

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

Ekorn::Pipeline::JSON's `to_json` and `to_jsonl`, from Tooling's
[`:json`](#importing-dbixsquirreltooling), are sinks too, given a
`file` or an `fh`: they write each result as JSON, and give how many.

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

say $dbh->iterate('SELECT title FROM album', sub { split ' ', $_->[0] }, count_items);    # 7
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

Where code reads a row's columns by name, a result set makes each row
an object, with a method for each column, named in lower case, so
`$artist->name` reads as it would in a class of your own. It's read
as any iterator is, and its stages see the objects:

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

A column whose name can't be a method's, such as `COUNT(*)`, or one a
method of the class already has, is read with `get_column`, by its
name, in any case, or its position:

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

my $next  = Ekorn::Pipeline->new(pluck)->iterator($dbh->iterate('SELECT name FROM artist ORDER BY id'));
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

my %on_my_phone = map { $_ => 1 } 'Dancing Queen', 'Parklife', 'Sunshine of Your Love';
my $to_copy = Ekorn::Pipeline->new(
    drop_if { $on_my_phone{ $_->[0] } },
    pluck('name'),
);
my $sql = 'SELECT name, plays FROM track ORDER BY plays DESC';
say join ', ', $dbh->iterate($sql, $to_copy)->all;
# Girls & Boys, Knowing Me, Knowing You, Country House
say join ', ', $dbh->iterate(
    $sql,
    $to_copy,
    take(1),
)->all;
# Girls & Boys
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
definitions](#defining-them-as-the-program-runs) take names too, and
the Sugar's [`pipeline`](#defining-them-on-use) names pipelines as
well. Ekorn's reference has the rules, in [Named
pipelines](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md#named-pipelines).

```perl
use Ekorn::Pipeline;

Ekorn::Pipeline->named(first_column => sub { $_->[0] });
say join ' ', $dbh->iterate('SELECT name FROM artist ORDER BY id', pipeline('first_column', take(2)))->all;    # Abba Blur
```

### pipe and tap

Database and statement handles both have these methods, from
Ekorn::Pipeline::Pipes. Each runs the handle itself through stages:
the first stage is called with the handle, and the rest with what
comes out of the stage before. On a statement handle, the statement
handle goes through the stages instead.
[pipe and
tap](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md#pipe-and-tap-ekornpipelinepipes),
in Ekorn's reference, says how to give a class of your own the same.

`pipe` is for work that starts from the handle and ends in values: it
returns what comes out of the last stage, all of it in list context,
or the first in scalar context. A stage that dies makes it croak,
naming the stage (see [When a stage dies](#when-a-stage-dies)).

```perl
my @names = $dbh->pipe(
    sub ($dbh) { @{ $dbh->selectcol_arrayref('SELECT name FROM artist ORDER BY id') } },
    sub {uc},
);
say "@names";    # ABBA BLUR CREAM

my $sth = $dbh->prepare('SELECT name FROM artist WHERE id = ?');
say scalar $sth->pipe(sub ($sth) { $sth->execute(2); $sth->fetchrow_arrayref->[0] });    # Blur
```

`tap` is for a side job in the middle of a chain of method calls: it
drops what comes out, and returns the handle, however the stages end,
so the chain carries on after it.

```perl
my $n = $dbh->tap(sub ($dbh) { say 'tapped ', ref $dbh })->selectrow_array('SELECT COUNT(*) FROM artist');
say $n;
# tapped DBIx::Squirrel::db
# 3
```

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
    artist_names => [music => 'SELECT name FROM artist', pluck],
    artist       => [music => 'SELECT * FROM artist WHERE id = :id'],
};
use DBIx::Squirrel::Sugar pipeline => {loud => [sub {uc}]};
use DBIx::Squirrel::Sugar qw(database statement);
```

Given a hash reference after `database` or `statement`, `use` defines
each database or statement named in it, with its arguments in an array
reference. After `pipeline`, it takes what Ekorn::Pipeline::Sugar
takes, a hash reference, or an array reference of names and stages in
turn, and names each pipeline, with a function of its name, as that
module does. It names them before it defines any statement, wherever
they're given, so a statement in the same `use` can name one. It
doesn't give the word `pipeline`, which Ekorn::Pipeline::Factories
exports, and Tooling too: [The Sugar's
pipelines](#the-sugars-pipelines) says how to use them. It gives the
package each function while the package is
compiled, so the function can be called without parentheses. The
arguments are worked out then too: the environment, literals, and what
a `BEGIN` block has set are there, but a variable the program sets as
it runs is not yet. `use` also gives the package the `database` and
`statement` functions, and, given just their names, only those.

### Defining them as the program runs

`use` defines databases and statements as the program compiles, from
what's known then. Where the arguments aren't known until the program
runs, such as a data source read from a configuration file, `database`
and `statement` define them then, and give the package the same
functions. A function defined so isn't known as the program compiles,
so it's called with parentheses. Given just a name, `database` is the
handle, from anywhere in the program:

```perl
database(archive => 'dbi:SQLite:dbname=music.db', {RaiseError => 1});
statement(albums_of => archive => 'SELECT title FROM album WHERE artist_id = ? ORDER BY year', pluck);

say join ', ', albums_of(2, keep_all);    # Parklife, The Great Escape
say ref database('archive');              # DBIx::Squirrel::db
```

A statement's database is found when its function runs, so it can be
defined after the statement. Each database is defined once in a
program, by a name a function can have, which the package can't have
a function of already.

A stage in a definition can be a pipeline's **name**, as
Ekorn::Pipeline names them with `named`: words joined by `::`. A name
is looked up as the statement is defined, in the package defining it,
unless it's qualified, as `My::Module::clean`, and stands in its place
among the stages. So it must be defined first, and one that isn't
croaks then: `No pipeline named main::clean`. On `use`, the definition
is made as the program compiles, so give the pipeline after
`pipeline`, in the same `use` or one before it, or name it in a
`BEGIN` block above it.

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

An unblessed hash reference or `undef` straight after the statement is
the attributes to prepare it with. The statement can be a statement
handle, which is itself executed, or iterated over.

```perl
use DBIx::Squirrel::Sugar database => {music => ['dbi:SQLite:dbname=music.db', '', '', {RaiseError => 1}]};

say music('SELECT name FROM artist WHERE id = ?', 1)->fetchrow_arrayref->[0];    # Abba
say ref music('SELECT name FROM artist', pluck);                                 # DBIx::Squirrel::Iterator
say join ' ', music(
    'SELECT name FROM artist ORDER BY id',
    pluck,
    keep_all,
);
# Abba Blur Cream
```

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
use DBIx::Squirrel::Sugar
    statement => {
        artist_names => [music => 'SELECT name FROM artist ORDER BY id', pluck],
        loud_names   => [music => 'SELECT name FROM artist ORDER BY id', pluck, 'shouted'],
        artist       => [music => 'SELECT * FROM artist WHERE id = :id'],
    },
    pipeline => {shouted => [sub {uc}]};

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

### The Sugar's pipelines

<!-- not run -->
```perl
@results = shouted(@values);
@results = shouted(@values, $pipeline);
$it      = music($statement, @bind_values, pipeline('shouted'));
$it      = artist_names(@bind_values, pipeline('shouted'));
```

Each pipeline after `pipeline`, on `use`, is named in the package, and
the package gets a function of its name. The function runs the values
it's given through the pipeline, and returns what comes out: a list in
list context, and in scalar context a sink's result, or how many values
came out. A pipeline given last adds its stages to that call.

A string given to a database's or a statement's function is a bind
value, so to use a named pipeline for one call, give the pipeline
itself: `pipeline`, given a name alone, returns the pipeline of that
name.

```perl
say join ' ', shouted('abba', 'blur');                       # ABBA BLUR
say join ' ', artist_names pipeline('shouted'), keep_all;    # ABBA BLUR CREAM

my @loud = music 'SELECT name FROM artist ORDER BY id',
    pluck('name'), pipeline('shouted'), keep_all;
say "@loud";    # ABBA BLUR CREAM
```

## 13. Caching and connections

The user guide's [chapter 13](HOWTO.md#13-caching-and-connections).

### prepare_cached

The DBI's cache of statement handles works as it does with the DBI,
but for two things: how a statement's placeholders, and an iterator
reading a handle, bear on which handle is handed out.

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
my $first = $dbh->prepare_cached($sql)->iterate(pluck);
$first->next;
my $second = $dbh->prepare_cached($sql)->iterate(pluck);
say $first->sth == $second->sth ? 'shared' : 'a handle each';    # a handle each
say join ' ', $second->all;    # Abba Blur Cream
say join ' ', $first->all;     # Blur Cream
```

### connect_cached

Code that connects in several places, such as a function for each
request, shares one connection by connecting with `connect_cached`.
It takes its arguments as `connect` does, and calls `connect` when it
needs a new connection, so it croaks on failure too. DBIx::Squirrel's
own attributes are part of its key, so a handle made to fetch rows as
hashes isn't handed to code expecting arrays:

```perl
my $one   = DBIx::Squirrel->connect_cached('dbi:SQLite:dbname=music.db', {RaiseError => 1});
my $two   = DBIx::Squirrel->connect_cached('dbi:SQLite:dbname=music.db', {RaiseError => 1});
my $hashy = DBIx::Squirrel->connect_cached('dbi:SQLite:dbname=music.db', {RaiseError => 1, ekorn_slice => {}});
say $one == $two   ? 'shared' : 'apart';    # shared
say $one == $hashy ? 'shared' : 'apart';    # apart
```

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
    pluck,
    My::Stages::prefixed('#'),
)->all;
# #Abba #Blur #Cream

eval { My::Stages::prefixed('') };
print $@;    # Expected a prefix at ... line ...
```

`croakf` makes its message with `sprintf`. The format is a literal,
written in the code; values go in as arguments, through `%s` and the
like, never as the format. A format made from data does whatever its
`%` directives say: `%999999999s` makes a string of a gigabyte. A
literal `%` is `%%`.

```perl
package My::Columns {
    use DBIx::Squirrel::Errors qw(croakf);

    sub exactly ($n) {
        croakf 'Expected %d %s, not %d%%', 3, 'columns', $n unless $n == 3;
        return $n;
    }
}

eval { My::Columns::exactly(50) };
print $@;    # Expected 3 columns, not 50% at ... line ...
```

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
`DBIx::Squirrel::Stages::CSV`, in a distribution named
`DBIx-Squirrel-Stages-CSV`. Have it require the DBIx::Squirrel it was
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
Ekorn::Pipeline takes one, by offering `EKORN_SOURCE`, so a pipeline's
`iterator`, a chain made with `|`, and `@{}` can read it. Each run
reading it starts a fresh run of the statement, from its first row:

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

my $it   = $dbh->iterate('SELECT name FROM artist ORDER BY id', pluck);
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
values, has some other context, or none. `pluck` and `as_hash` read
it, and so can a stage of yours; `result_original` gives the same
row, which the source also gives Ekorn as its original. While a flush
gives its values, which come from every row, not one,
`Ekorn::Pipeline::ending()` is true, and the row is no value's;
`result_original` gives `undef` then.

```perl
my $columns = sub ($row) {
    my $names = Ekorn::Pipeline::run_context()->{columns};
    return join ', ', map {"$names->[$_]=$row->[$_]"} keys @$names;
};
say join '; ', $dbh->iterate('SELECT id, name FROM artist ORDER BY id', $columns)->all;    # id=1, name=Abba; id=2, name=Blur; id=3, name=Cream
```

The context is the run's: a pipeline called inside a stage has its
own, which has no row unless it too reads a statement.

### What a call takes as stages

`iterate`, `results`, an iterator's `reset`, the select methods,
`pipe`, `tap` and the Sugar's functions take stages at the end of
their arguments. A stage is whatever Ekorn::Pipeline's `is_stage` is
true of: a code reference, a pipeline, or one of Ekorn's stage
objects. Those include stages made with `gather`, Ekorn's words and
the canned stages, and its sinks. Anything else is a bind value, so an
object of your own given as a value stays one. A sink, if one is last,
says what the call gives (see [8. Sinks](#8-sinks)). Only a Sugar
statement's definition takes pipelines' names, as strings.

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
| `Expected a reference to a HASH or ARRAY` | The first argument after the statement in `do`, `iterate`, `results` or a select method was an unblessed reference, but not to a hash or an array. An object there is a bind value. |
| `Expected %d bind values, not %d` | A statement with numbered placeholders was given more or fewer values than its highest number; or a row given to `execute_for_fetch` had more or fewer values than the statement has placeholders. |
| `Expected names and values in pairs` | A statement with named placeholders was given an odd number of values. |
| `Expected a placeholder of the statement (%s)` | A value was given for a placeholder the statement doesn't have. |
| `Expected no list placeholder in a statement for rows of values (%s)` | `execute_array`, `execute_for_fetch` or `bind_param_array` was called on a statement with a list placeholder, whose handle is prepared for lists of one length. |
| `Expected a value for each placeholder (none for %s)` | A statement with named placeholders wasn't given a value for each name, or a statement with numbered or named placeholders was executed without values when some had none bound. |
| `Expected bind values with a statement taking a list (%s)` | `prepare` or `prepare_cached` was given a statement taking a [list](#lists). Each list placeholder is named, and a `?` is named by its position: `...? at 2`. |
| `Expected a placeholder to take a list everywhere or nowhere (%s)` | A placeholder was used with `...` in one place and without it in another. |
| `Expected no list placeholder with pg_placeholder_dollaronly (%s)` | A `$1` placeholder took a list under DBD::Pg's `pg_placeholder_dollaronly`. |
| `Expected a reference to an ARRAY for a list (%s)` | A list placeholder was given a plain value, `undef`, or a reference to something other than an array. |
| `Expected at least one value in a list (%s)` | A list placeholder was given an empty list. |
| `Expected plain values in a list (%s)` | A list held an unblessed reference, as `[[1, 2]]` does to a statement whose one value is a list. |
| `Expected %d values in a list, as prepared, not %d (%s)` | The handle of a statement taking a list was executed or bound with a list of another length. |

#### Iterators and result sets

| Message | Cause |
|---|---|
| `Expected a DBIx::Squirrel statement handle` | `DBIx::Squirrel::Iterator->new` wasn't given a `DBIx::Squirrel::st`. |
| `Expected only one item, but there were more` | A warning: `single`, `keep_single` or `take_single` found a second result, and gave the first. |
| `Expected the statement handle's other iterator to be finished` | Another iterator over the same statement handle has results left. |
| `Expected ekorn_result_class to be a subclass of DBIx::Squirrel::Result (%s)` | `ekorn_result_class` named a class that isn't one. |
| `Expected a column of the row (%s)` | `get_column`, `pluck` or `as_hash` was given a name or position the row doesn't have. |
| `Expected use Ekorn::Pipeline::Operators in scope, for %s` | `\|` or `@{}` was used on an iterator where the operators aren't in force. |

#### Pipelines

| Message | Cause |
|---|---|
| `Expected stage #%d to be a stage: a code reference, a pipeline, or an object offering a stage's role method` | Something passed as a stage to a pipeline, `pipe` or `tap` wasn't one. No stage runs. |
| `Expected stage #%d to be a stage: a code reference, a pipeline or its name, or an object offering a stage's role method` | Something given to `pipeline`, or to `named`, wasn't a stage or a pipeline's name. |
| `Expected a code reference` | The block given to `gather`, `take_while`, `drop_while`, `take_if`, `drop_if`, `collect` or `peek` wasn't a code reference. |
| `Expected a source: a code reference, or an object offering EKORN_SOURCE` | A pipeline's `iterator` was given something it can't read. |
| `Expected stage #%s, made with gather, to return a code reference or a pipeline, and optionally a flush and an end` | The block given to `gather` for that stage returned something else. |
| `Pipeline stage #%s failed at %s line %d:` | A stage, or its flush, died. The message it died with follows, indented. See [When a stage dies](#when-a-stage-dies). |
| `Pipeline end of %s failed at %s line %d:` | An end died, in a run that hadn't died already: the source's, as `the source`, or a stage's, as `stage #2`. |
| `The end of %s died while the run was already dying: %s` | A warning: an end died in a run that had died already. The run's own error is the one thrown. |
| `Stop used outside a pipeline` | `Stop` was called where no pipeline was running to catch it. |
| `No pipeline named %s` | A name, in a Sugar statement's definition or given to `pipeline`, has no pipeline. |

#### Canned stages and sinks

| Message | Cause |
|---|---|
| `Expected a count of 0 or more` | `take`, `drop` or `keep` was given something other than a whole number. |
| `Expected a batch size of 1 or more` | `batch` was given something other than a whole number above 0. |
| `Expected a column, by name or position` | `pluck` was given an undefined column, or an empty name. |
| `Expected a column name` | `as_hash` was given an undefined or empty column name. |
| `Expected one column to pluck, not %d` | `pluck`, given no column, had a row of more than one column, or of none. |
| `Expected a statement to read, for the column names` | `as_hash`, or `pluck` with a name for an array row or a position for a hash row, ran where no statement was being read, such as in a pipeline called with values. |
| `Expected a row: an array, a hash or a row object` | `pluck` or `as_hash` was given a value that isn't a row. |
| `Expected a reference to a scalar` | `count_into` was given something else. |
| `Expected an open filehandle` | `dump_to` or `to_fh` was given something else. |

#### Sugar

| Message | Cause |
|---|---|
| `Expected database, pipeline or statement, not %s` | `use DBIx::Squirrel::Sugar` was given something else. |
| `Expected the pipelines after pipeline in a HASH or an ARRAY of pairs` | What came after `pipeline` was something else. This, and the other errors in the pipelines' definitions, are Ekorn::Pipeline::Sugar's. |
| `Expected the pipelines after pipeline in pairs of a name and an ARRAY` | The array reference after `pipeline` had an odd number of items. |
| `Expected the arguments to connect to %s in an ARRAY` | A database's definition, given to `use`, wasn't an array reference. |
| `Expected the statement %s in an ARRAY` | A statement's definition, given to `use`, wasn't an array reference. |
| `Expected a name for a database (%s)` | The name can't be a function's. |
| `Expected a name for a statement (%s)` | The name can't be a function's. |
| `Expected a database defined once (%s)` | The name was given to another database already. |
| `Expected a database named %s` | `database` was given a name no database has. |
| `Expected a database and a statement for %s` | A statement's definition didn't name its database, or have its SQL. |
| `Expected only stages after the statement for %s: code references, pipelines or their names, or objects offering a stage's role method` | A statement's definition had something after the statement and its attributes that's neither a stage nor a pipeline's name. |
| `Expected no function of the name in %s already (%s)` | The package has a function of that name already, such as a sink it imported. |

## Making each kind of part

This section is for developers making parts for DBIx::Squirrel's
users. It says what a statement's run gives each piece of a part. Then
it works through an example of each kind DBIx::Squirrel adds to, made
with a word and as a class of your own. The protocol itself, what each
piece is called with, what it returns, and the rules every part keeps,
is Ekorn::Pipeline's, and its reference has it in full, in [Making each
kind of part](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/REFERENCE.md#making-each-kind-of-part).
Each example runs against the examples' database, and its comments say
what it prints.

### What a statement's run gives each piece

A part reading a statement, through `iterate`, `results`, a Sugar
function, `|`, or a pipeline of yours reading an iterator, finds the
statement in the [run's context](#the-runs-context). What each piece
finds there, and what [Context](#context)'s functions give it:

| Piece | `Ekorn::Pipeline::run_context()` | `result_original` | `result_number` |
|---|---|---|---|
| **set-up** | nothing: the run hasn't read the statement yet | `undef` | `undef` |
| a stage's **step** | `statement`, `columns`, and the `row` this value came from | the row | the number of the result being made |
| a stage's **flush** | `statement` and `columns`; `ending()` is true, and the row is no value's | `undef` | the number of the first value it gives |
| a sink's **step** | `statement`, `columns` and `row`, as for a stage | the row | the number of the value it's given |
| a sink's **flush** | as for a stage's flush | `undef` | the results so far, plus one |
| an **end** | `statement` and `columns`; the `row` is `undef` | `undef` | `undef` |

So a stage that needs the statement's columns reads them in its step,
the first time it's called in the run, and keeps them in a variable of
the set-up, as `pluck` and `as_hash` do. It can't read them in the
set-up, which runs before the statement does.

### A stage for rows, with the word `gather`

A stage that gives each row, an array, as its columns and values, and
says how many rows there were once they run out. It croaks if what it
reads isn't a statement, in a module of stages, as [Stages for
others](#stages-for-others) says, so the message names the caller's
line:

```perl
package My::Stages {
    use DBIx::Squirrel::Errors qw(croakf);
    use DBIx::Squirrel::Tooling qw(gather);

    our @CARP_NOT = @DBIx::Squirrel::Errors::INTERNAL;

    sub labelled () {
        return gather {
            my($columns, $n) = (undef, 0);    # this run's
            return {
                step => sub ($row) {
                    $columns //= do {
                        my $context = Ekorn::Pipeline::run_context();
                        croakf 'Expected a statement to read, for its columns'
                            unless ref $context eq 'HASH'
                            && $context->{statement} isa 'DBIx::Squirrel::st';
                        $context->{columns};
                    };
                    $n++;
                    return join ', ', map {"$columns->[$_]=$row->[$_]"} 0 .. $#$columns;
                },
                flush => sub () {"($n rows)"},
            };
        };
    }
}

say for $dbh->iterate(
    'SELECT id, name FROM artist ORDER BY id',
    My::Stages::labelled,
)->all;
# id=1, name=Abba
# id=2, name=Blur
# id=3, name=Cream
# (3 rows)

say for $dbh->iterate(
    'SELECT id, name FROM artist ORDER BY id',
    My::Stages::labelled,
    take(1),
)->all;
# id=1, name=Abba

eval { Ekorn::Pipeline->new(My::Stages::labelled)->([1, 'Abba']) };
print $@;
# Pipeline stage #1 failed at ... line ...:
#     Expected a statement to read, for its columns at ... line ...
```

In the second run, `take(1)`, after it, stopped the run while rows
were still to come, so its flush wasn't called, as Ekorn's rules say.
Called with values, the pipeline reads no statement, so the stage
croaks.

### The same stage, as a class

A class of your own can be the same stage, by offering `EKORN_STAGE`,
called at the start of each run with the object, and returning the
pieces, as the set-up did. The object keeps its settings, and each run
its own columns:

```perl
package My::Labelled {
    sub new ($class, %options) { bless {between => $options{between} // ', '}, $class }

    sub EKORN_STAGE ($self) {
        my $columns;    # this run's
        return {
            step => sub ($row) {
                $columns //= Ekorn::Pipeline::run_context()->{columns};
                return join $self->{between}, map {"$columns->[$_]=$row->[$_]"} 0 .. $#$columns;
            },
        };
    }
}

say for $dbh->iterate(
    'SELECT id, name FROM artist ORDER BY id',
    My::Labelled->new(between => ' '),
)->all;
# id=1 name=Abba
# id=2 name=Blur
# id=3 name=Cream
```

### A sink into a table, with the word `sink_one`

A sink that inserts each value into a table, and gives how many it
inserted. Its set-up begins a transaction, and its end commits it only
if the run ended `done`, so a run that dies, or is stopped, leaves the
table as it was:

```perl
sub into ($dbh, $table) {
    return sink_one {
        my $n = 0;
        $dbh->begin_work;
        my $sth = $dbh->prepare("INSERT INTO $table (name) VALUES (?)");
        return {
            step  => sub ($name) { $sth->execute($name); $n++ },
            flush => sub ()      {$n},
            end   => sub ($how)  { $how eq 'done' ? $dbh->commit : $dbh->rollback },
        };
    };
}

$dbh->do('CREATE TEMP TABLE copy (name TEXT)');

say $dbh->iterate(
    'SELECT name FROM artist ORDER BY id',
    pluck('name'),
    into($dbh, 'copy'),
);
# 3

eval {
    $dbh->iterate(
        'SELECT name FROM artist ORDER BY id',
        pluck('name'),
        sub { die "no Cream\n" if $_ eq 'Cream'; $_ },
        into($dbh, 'copy'),
    );
};
print $@;
# Pipeline stage #2 failed at ... line ...:
#     no Cream

say $dbh->selectrow_array('SELECT COUNT(*) FROM copy');    # 3
```

The second run inserted Abba and Blur, then died at Cream, so the sink's
end was told `died`, and rolled them back: the table has the first
run's three rows.

### The same sink, as a class

A class offers `EKORN_SINK_ONE` for a sink of one result, or
`EKORN_SINK_MANY` for a sink of many, returning the same pieces:

```perl
package My::Into {
    sub new ($class, $dbh, $table) { bless {dbh => $dbh, table => $table}, $class }

    sub EKORN_SINK_ONE ($self) {
        my($dbh, $n) = ($self->{dbh}, 0);
        $dbh->begin_work;
        my $sth = $dbh->prepare("INSERT INTO $self->{table} (name) VALUES (?)");
        return {
            step  => sub ($name) { $sth->execute($name); $n++ },
            flush => sub ()      {$n},
            end   => sub ($how)  { $how eq 'done' ? $dbh->commit : $dbh->rollback },
        };
    }
}

say $dbh->iterate(
    'SELECT name FROM artist ORDER BY id',
    pluck('name'),
    take(2),
    My::Into->new($dbh, 'copy'),
);
# 2

say $dbh->selectrow_array('SELECT COUNT(*) FROM copy');    # 5
$dbh->do('DROP TABLE copy');
```

`take(2)` stopped the run, but before the sink, so the sink got every
value it was going to get: its end was told `done`, and it committed.

### Row classes and functions that take stages

A row class of your own, for `results`, is a subclass of
DBIx::Squirrel::Result with methods of your own: see [Methods of your
own](#methods-of-your-own). A function that takes stages from its
caller hands them to `iterate`: see [A function that takes
stages](#a-function-that-takes-stages). Neither has pieces of its own.

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
| `execute_array`, `execute_for_fetch` and `bind_param_array` | For `?`, and other styles as far as the driver reads them. | For every style: a row's values in placeholder order, or a hash by name; `bind_param_array` by name. |
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
| `DBIx::Squirrel::Pipeline->new(...)` | fails on a fresh install, as the module is no longer shipped; a copy that 2.x installed still loads, until it's deleted | `Ekorn::Pipeline->new(...)`, or `pipeline(...)` from Ekorn::Pipeline::Factories |
| `$x isa 'DBIx::Squirrel::Pipeline'` | false | `$x isa 'Ekorn::Pipeline'` |
| `DBIx::Squirrel::Stop->throw`, or a subclass of DBIx::Squirrel::Stop | fails: it's no longer a class | `Ekorn::Pipeline::Stop->throw`, and subclass `Ekorn::Pipeline::Stop` |
| `ref $stage eq 'CODE'`, or `is_coderef($stage)`, for a stage made by `take`, `gather` and the like | false: they're objects now, called as code references | `is_stage($stage)`, from Ekorn::Pipeline |
| A `gather` block's second part, "the end function" | the same, now called the flush | nothing; an end, told how the run ended, can follow it |
| `iterator` in a pipeline of your own reading an iterator | `undef` | keep the iterator in a variable the stage can see |
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
    statement => {artist_id => [db => 'SELECT ArtistId FROM artists WHERE Name = ?', pluck]};
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
| `DBIx::Squirrel::Transform::JSON::Syck` and `DBIx::Squirrel::Transform::YAML::Syck`. | For JSON, `from_json` and `to_json`, from Ekorn::Pipeline::JSON, by Tooling's [`:json`](#importing-dbixsquirreltooling). For YAML, a stage of your own calling a YAML module: see [Stages for others](#stages-for-others). |
| `get_file_contents`, `slurp`, `uncompress`, `unmarshal` and `utf8decode`, from DBIx::Squirrel::util. | Path::Tiny, IO::Uncompress::Bunzip2, a JSON module, and Encode. |
| `load_tuples`, on a database handle. | `prepare` and `execute`, in a loop. |
| `statement_digest`, `statement_normalise`, `statement_study` and `statement_trim`, on a statement handle. | Gone. DBIx::Squirrel::Placeholders has `study_sql` and `trim_sql`, but they're internal, and may change. |

## Index

Every module, A to Z, and each of its functions and methods, A to Z,
with a synopsis of all its forms, what it does, and how it's exported.
Each ends with a link to its section, which says more. A module marked
internal is for DBIx::Squirrel's own use, and may change without
notice.

### DBIx::Squirrel

The class you connect with; a subclass of `DBI`. `use DBIx::Squirrel`
takes what the DBI exports, such as `:sql_types`, and nothing else
(see [Importing](#importing)).

#### connect

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

See [connect](#connect).

#### connect_cached

<!-- not run -->
```perl
$dbh = DBIx::Squirrel->connect_cached($data_source, $username, $password);
$dbh = DBIx::Squirrel->connect_cached($data_source, $username, $password, \%attr);
$dbh = DBIx::Squirrel->connect_cached($data_source, \%attr);
```

As the DBI's `connect_cached`: it returns the handle it connected with
before, given the same arguments, or connects, and keeps the handle.
It takes its arguments as `connect` does, and croaks on failure, as
`connect` does. DBIx::Squirrel's own attributes are part of the
cache's key, so a handle with other `ekorn_` attributes is another
connection.

See [connect_cached](#connect_cached).

### DBIx::Squirrel::Context

What a stage can ask about the result it's making. Nothing by default;
each upon request, and in Tooling's `:context`.

#### iterator

<!-- not run -->
```perl
$it = iterator();
```

Returns the iterator running the stage, in an iterator's or result
set's own stages; elsewhere, and outside a stage, `undef`. Through it
a stage can reach the rest: its `sth` is the statement handle, the
statement handle's `Database` is the database handle, and its
[column_names](#column_names) are the statement's columns. Exported upon
request.

See [Context](#context).

#### result_number

<!-- not run -->
```perl
$n = result_number();
```

Returns the number of the result being made, from 1. It counts
results, not rows: while a stage drops rows, the number stays the
same, and each value a stage returns in place of one row is a result
of its own. In a flush of a stage made with [gather](#gather), it's
the number of the first value the flush returns. It works in any run,
each counting its own results, and is `undef` outside one. It has an
empty prototype, so `result_number + 1` adds one. Exported upon
request.

See [Context](#context).

#### result_original

<!-- not run -->
```perl
$row = result_original();
```

Returns the row the result is being made from, as it was fetched,
before any stage changed it; for a result set, the row object. In a
flush of a stage made with [gather](#gather), and the stages after it,
it's `undef`, as what a flush gives comes from every row, not one. In
a run reading no statement, it's the value the run's source gave, or
that was pushed. It's Ekorn::Pipeline::Context's own, with an empty
prototype. Exported upon request.

See [Context](#context).

### DBIx::Squirrel::db

The database handle class; a subclass of `DBI::db`. Exports nothing.

#### do

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

See [do](#do).

#### iterate

<!-- not run -->
```perl
$it     = $dbh->iterate($statement, \%attr, @bind_values, @stages);
$it     = $dbh->iterate($statement, @bind_values, @stages);
@result = $dbh->iterate($statement, @bind_values, @stages, $sink);
```

On a database handle, `iterate` prepares the statement, as `prepare`
does, and returns a `DBIx::Squirrel::Iterator` over its results. As
with `do`, the attributes may be left out. On a statement handle, it
returns an iterator over that statement's results.

See [iterate](#iterate).

#### pipe

<!-- not run -->
```perl
@results = $dbh->pipe(@stages);
$result  = $dbh->pipe(@stages);
```

Runs the handle through the stages, and returns what comes out of the
last one: all of it in list context; in scalar context, the first
value, or `undef` if none came out. With no stages, it returns the
handle. A stage that dies makes `pipe` croak, naming the stage (see
[When a stage dies](#when-a-stage-dies)).

See [pipe and tap](#pipe-and-tap).

#### prepare

<!-- not run -->
```perl
$sth = $dbh->prepare($statement);
$sth = $dbh->prepare($statement, \%attr);
```

Prepares a statement, with placeholders in any of the
[styles](#the-styles), and returns a `DBIx::Squirrel::st`.

The statement can be a string, an array reference of lines, which are
joined with spaces, a code reference returning either, or a statement
handle, whose statement is prepared again.

See [prepare](#prepare).

#### prepare_cached

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

See [prepare_cached](#prepare_cached).

#### results

<!-- not run -->
```perl
$results = $dbh->results($statement, \%attr, @bind_values, @stages);
$results = $dbh->results($statement, @bind_values, @stages);
@result  = $dbh->results($statement, @bind_values, @stages, $sink);
```

As [`iterate`](#iterate), returning a `DBIx::Squirrel::Results`, or a
sink's result, if the last stage is a sink. A result set is an
iterator whose rows are objects, with a method for each column, named
in lower case. The stages see the objects. A result set has the
iterator's methods, and no others.

See [results](#results).

#### selectall_array

<!-- not run -->
```perl
@rows    = $dbh->selectall_array($statement, \%attr, @bind_values);
@rows    = $dbh->selectall_array($statement, @bind_values);
@results = $dbh->selectall_array($statement, \%attr, @bind_values, @stages);
$count   = $dbh->selectall_array($statement, \%attr, @bind_values, @stages);
```

Returns every row, as a list, the rows `selectall_arrayref` gives, as
the DBI's does. Given stages, it pushes each row through them in turn,
which makes it the select method most like `iterate`, but with every
row fetched first.

See [The select methods](#the-select-methods).

#### selectall_arrayref

<!-- not run -->
```perl
$ary_ref = $dbh->selectall_arrayref($statement, \%attr, @bind_values);
$ary_ref = $dbh->selectall_arrayref($statement, @bind_values);
@results = $dbh->selectall_arrayref($statement, \%attr, @bind_values, @stages);
```

Returns every row, as an array reference of rows, each an array
reference, or a hash reference given the attribute `Slice => {}`, as
the DBI's does. Given stages, it pushes that one reference through
them, so a stage gets all the rows at once.

See [The select methods](#the-select-methods).

#### selectall_hashref

<!-- not run -->
```perl
$hash_ref = $dbh->selectall_hashref($statement, $key_field, \%attr, @bind_values);
$hash_ref = $dbh->selectall_hashref($statement, $key_field, @bind_values);
@results  = $dbh->selectall_hashref($statement, $key_field, \%attr, @bind_values, @stages);
```

Returns every row, in a hash reference keyed by the values of
`$key_field`, each row a hash reference, as the DBI's does. The key
field comes before the attributes, and can be an array reference of
fields, for nested keys. Given stages, it pushes that one reference
through them.

See [The select methods](#the-select-methods).

#### selectcol_arrayref

<!-- not run -->
```perl
$ary_ref = $dbh->selectcol_arrayref($statement, \%attr, @bind_values);
$ary_ref = $dbh->selectcol_arrayref($statement, @bind_values);
@results = $dbh->selectcol_arrayref($statement, \%attr, @bind_values, @stages);
```

Returns the first column of every row, as an array reference, or the
columns the attribute `Columns` names, as the DBI's does. Given
stages, it pushes that one reference through them.

See [The select methods](#the-select-methods).

#### selectrow_array

<!-- not run -->
```perl
@row_ary = $dbh->selectrow_array($statement, \%attr, @bind_values);
@row_ary = $dbh->selectrow_array($statement, @bind_values);
@results = $dbh->selectrow_array($statement, \%attr, @bind_values, @stages);
```

Returns the first row's values, as a list, or nothing if there's no
row. Given stages, it pushes each of the row's values through them.

See [The select methods](#the-select-methods).

#### selectrow_arrayref

<!-- not run -->
```perl
$ary_ref = $dbh->selectrow_arrayref($statement, \%attr, @bind_values);
$ary_ref = $dbh->selectrow_arrayref($statement, @bind_values);
@results = $dbh->selectrow_arrayref($statement, \%attr, @bind_values, @stages);
```

Returns the first row, as an array reference, or `undef` if there's no
row. Given stages, it pushes that one reference through them.

See [The select methods](#the-select-methods).

#### selectrow_hashref

<!-- not run -->
```perl
$hash_ref = $dbh->selectrow_hashref($statement, \%attr, @bind_values);
$hash_ref = $dbh->selectrow_hashref($statement, @bind_values);
@results  = $dbh->selectrow_hashref($statement, \%attr, @bind_values, @stages);
```

Returns the first row, as a hash reference keyed by the column names,
as `fetchrow_hashref` keys them, or `undef` if there's no row. Given
stages, it pushes that one reference through them.

See [The select methods](#the-select-methods).

#### tap

<!-- not run -->
```perl
$dbh = $dbh->tap(@stages);
```

Runs the handle through the stages for their side effects, drops what
comes out, and returns the handle, however the stages end: having run
out of values, stopped, or with no stages at all. So a chain of method
calls can carry on after it. A stage that dies makes `tap` croak, as
`pipe` does.

See [pipe and tap](#pipe-and-tap).

### DBIx::Squirrel::Errors

Reports errors at the caller's line. Internal, apart from what a
module of stages uses: `croakf`, and `@INTERNAL`, the packages an
error passes over, for a module's `@CARP_NOT`. Nothing by default.

#### croakf

<!-- not run -->
```perl
use DBIx::Squirrel::Errors qw(croakf);

croakf $format, @values;
```

Croaks with a message made by `sprintf` from a format and its values,
reported at the line `croak` would report it at. With `@CARP_NOT` set
to `@DBIx::Squirrel::Errors::INTERNAL`, that's the line that called
DBIx::Squirrel. It's the one function of DBIx::Squirrel::Errors for
others: the rest are for the handles. Exported upon request.

See [Stages for others](#stages-for-others).

### DBIx::Squirrel::Gather

A stage made afresh for each run, with a flush and an end: Ekorn's
`gather`, by default.

#### gather

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
returns the stage, and optionally a flush, called once the values run
out, and an end, told how the run ended. Exported by default.

See [gather](#gather).

### DBIx::Squirrel::Iterator

An iterator over a statement's results, and a source for
Ekorn::Pipeline. Where `use Ekorn::Pipeline::Operators` is in force,
`|` runs it through a sink or stages, and `@{}` gives every result
(see [11. Operators](#11-operators--and-)). Exports nothing.

#### all

<!-- not run -->
```perl
@results = $it->all;
$results = $it->all;
```

Returns the results still to come, reading the run to its end: as a
list, or, asked for one value, an array reference of them, never a
count. Either way, the statement is then finished, and `next` returns
nothing after, until [reset](#reset).

See [The iterator's methods](#the-iterators-methods).

#### column_names

<!-- not run -->
```perl
@names = $it->column_names;
```

Returns the names of the statement's columns, as `fetchrow_hashref`
would key them, following `FetchHashKeyName`. If the statement hasn't
been executed, it's executed first. The names are read when it's
executed, as some drivers, such as DBD::mysql, give none once the last
row is fetched. A statement without columns has no names, and nor does
one that couldn't be executed. A stage can ask for them through
[iterator](#iterator).

See [The iterator's methods](#the-iterators-methods).

#### EKORN_SOURCE

<!-- not run -->
```perl
($step, $end, $context) = $it->EKORN_SOURCE;
```

The role method that makes an iterator a source: a pipeline's
`iterator`, a chain made with `|`, and `@{}` call it, and you don't.
It returns what Ekorn::Pipeline's source protocol asks for: a step,
called for each next value, an end, told how the run ended, and the
run's context. Each call starts a fresh run of the statement, from its
first row, through the iterator's stages.

See [The iterator as a source](#the-iterator-as-a-source).

#### ended

<!-- not run -->
```perl
$how = $it->ended;
```

Returns how the last run ended: `done` when the rows ran out,
`stopped` when it was cut short, by `first`, by `single` finding a
second result, or by a stage that stopped, and `died` when a stage
died. While a run is going, and before one has started, it returns
nothing; [reset](#reset) starts a new run, so it returns nothing after
one. A run read with `|` or `@{}` is the iterator's last run too (see
[11. Operators](#11-operators--and-)).

See [The iterator's methods](#the-iterators-methods).

#### first

<!-- not run -->
```perl
$result = $it->first;
```

Returns the next result, or `undef` if there's none, and finishes the
statement, so the rest aren't fetched. `next` returns nothing after,
until [reset](#reset). The run ends `stopped`, as it was cut short.

See [The iterator's methods](#the-iterators-methods).

#### new

<!-- not run -->
```perl
$it = DBIx::Squirrel::Iterator->new($sth, @bind_values, @stages);
```

Returns an iterator over the rows of `$sth`, a `DBIx::Squirrel::st`,
without executing it. When it does, it's executed with `@bind_values`,
in any form [execute](#execute) takes, and each row runs through
`@stages`, the stages at the end of the arguments. `iterate` makes an
iterator this way, and is how you'd usually get one; a statement
handle that isn't DBIx::Squirrel's croaks, `Expected a DBIx::Squirrel
statement handle`.

See [The iterator's methods](#the-iterators-methods).

#### next

<!-- not run -->
```perl
while (my($result) = $it->next) { ... }
```

Returns the next result, or an empty list when there are no more. The
first call executes the statement, if it hasn't been, and each call
fetches rows as they're wanted, running each through the iterator's
stages until one comes out.

See [The iterator's methods](#the-iterators-methods).

#### reset

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
given.

See [reset](#reset).

#### single

<!-- not run -->
```perl
$result = $it->single;
```

Returns the next result, or `undef` if there's none, and finishes the
statement, as `first` does. If there's another result, it warns,
`Expected only one item, but there were more`, and returns the first.
It's for a statement that should give one result: the warning finds
one that lost its `LIMIT 1`, or its `WHERE`.

See [The iterator's methods](#the-iterators-methods).

#### sth

<!-- not run -->
```perl
$sth = $it->sth;
```

Returns the iterator's statement handle, a `DBIx::Squirrel::st`. It
changes when [reset](#reset) prepares a statement taking a
[list](#lists) again, for a list of another length.

See [The iterator's methods](#the-iterators-methods).

### DBIx::Squirrel::Manual::HowTo

The user guide, as POD, for MetaCPAN.

### DBIx::Squirrel::Manual::Reference

This reference, as POD, for MetaCPAN.

### DBIx::Squirrel::Placeholders

Finds the placeholders in a statement, and matches values to them.
Internal: its functions are for the handles.

### DBIx::Squirrel::Result

The base class of row objects. A row also has a method for each
column, as [Row objects](#row-objects) says, and can have methods of
your own (see [Methods of your own](#methods-of-your-own)). Exports
nothing.

#### get_column

<!-- not run -->
```perl
$value = $row->get_column($name);
$value = $row->get_column($position);
```

Returns a column's value by its name, in any case, or by its position,
from 0. It reaches every column, including those without a method. It
croaks if the row has no such column:
`Expected a column of the row (x)`.

See [get_column](#get_column).

### DBIx::Squirrel::Results

A result set: an iterator handing out rows as objects, with the
iterator's methods and no others. `results` makes one (see
[results](#results)). Exports nothing.

### DBIx::Squirrel::st

The statement handle class; a subclass of `DBI::st`. Exports nothing.

#### bind

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

See [bind](#bind).

#### bind_param

<!-- not run -->
```perl
$rv = $sth->bind_param($placeholder, $value);
$rv = $sth->bind_param($placeholder, $value, \%attr);
$rv = $sth->bind_param($placeholder, $value, $bind_type);
```

Binds one value, as the DBI's `bind_param` does, and returns what it
returns. The placeholder can be given by position, as with the DBI; by
number, for numbered placeholders, as `1` or `'$1'`; or by name, for
named ones, as `'id'` or `':id'`. The value is bound to every use of
the placeholder in the statement.

See [bind_param](#bind_param).

#### bind_param_array

<!-- not run -->
```perl
$rv = $sth->bind_param_array($placeholder, \@values);
$rv = $sth->bind_param_array($placeholder, $value);
$rv = $sth->bind_param_array($placeholder, \@values, \%attr);
```

Binds an array of values to a placeholder, a value for each row
[execute_array](#execute_array) executes, or one value for every
row, as the DBI's `bind_param_array` does, and returns what it
returns. The placeholder is named as for [bind_param](#bind_param):
by number or name, with or without the sigil, for numbered and named
placeholders. Attributes given are bound to every use of it.

See [execute_array](#execute_array).

#### execute

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
iterators and the select methods check the same way.

See [execute](#execute).

#### execute_array

<!-- not run -->
```perl
$tuples = $sth->execute_array(\%attr, @arrays);
($tuples, $rows) = $sth->execute_array(\%attr, @arrays);
$tuples = $sth->execute_array(\%attr);
```

Executes the statement once for each row of values, as the DBI's
`execute_array` does, and returns what it returns: in a list, the
rows executed and the rows changed. The rows come from `@arrays`, one
for each placeholder, in order, by number, or for names, in the order
each first appears; from those bound with
[bind_param_array](#bind_param_array); or from `ArrayTupleFetch` in
`%attr`. Each row's status goes in `ArrayTupleStatus`. A statement
with a list croaks.

See [execute_array](#execute_array).

#### execute_for_fetch

<!-- not run -->
```perl
$tuples = $sth->execute_for_fetch($fetch);
$tuples = $sth->execute_for_fetch($fetch, \@status);
($tuples, $rows) = $sth->execute_for_fetch($fetch, \@status);
```

Executes the statement once for each row `$fetch` returns, until it
returns nothing, as the DBI's `execute_for_fetch` does, and returns
what it returns. A row is an array of values, in the order
[execute_array](#execute_array) takes them, or, for named
placeholders, a hash of them by name. A statement with a list croaks.

See [execute_array](#execute_array).

#### iterate

<!-- not run -->
```perl
$it     = $sth->iterate(@bind_values, @stages);
```

On a database handle, `iterate` prepares the statement, as `prepare`
does, and returns a `DBIx::Squirrel::Iterator` over its results. As
with `do`, the attributes may be left out. On a statement handle, it
returns an iterator over that statement's results.

See [iterate](#iterate).

#### pipe

<!-- not run -->
```perl
@results = $sth->pipe(@stages);
$result  = $sth->pipe(@stages);
```

Runs the handle through the stages, and returns what comes out of the
last one: all of it in list context; in scalar context, the first
value, or `undef` if none came out. With no stages, it returns the
handle. A stage that dies makes `pipe` croak, naming the stage (see
[When a stage dies](#when-a-stage-dies)).

See [pipe and tap](#pipe-and-tap).

#### results

<!-- not run -->
```perl
$results = $sth->results(@bind_values, @stages);
```

As [`iterate`](#iterate), returning a `DBIx::Squirrel::Results`, or a
sink's result, if the last stage is a sink. A result set is an
iterator whose rows are objects, with a method for each column, named
in lower case. The stages see the objects. A result set has the
iterator's methods, and no others.

See [results](#results).

#### tap

<!-- not run -->
```perl
$sth = $sth->tap(@stages);
```

Runs the handle through the stages for their side effects, drops what
comes out, and returns the handle, however the stages end: having run
out of values, stopped, or with no stages at all. So a chain of method
calls can carry on after it. A stage that dies makes `tap` croak, as
`pipe` does.

See [pipe and tap](#pipe-and-tap).

### DBIx::Squirrel::Stages::Batch

Canned stages gathering values. Both by default, and in Tooling's
`:batch`.

#### batch

<!-- not run -->
```perl
batch($n)
```

Passes values on in batches of `$n`, each a new array reference. Once
the values run out, the last batch goes on, which may be shorter.
There's never an empty batch: with no values, there's no batch at all.
It holds no more than one batch at a time, so it suits loading or
sending rows in groups. It croaks, `Expected a batch size of 1 or
more`, if `$n` isn't a whole number above 0. Exported by default.

See [Batching and collecting](#batching-and-collecting).

#### collect

<!-- not run -->
```perl
collect
collect { ... }
collect(\&code)
```

Holds every value. Once they run out, it passes on an array reference
of them. Given a block, it calls the block once, with the values as
its arguments, and passes on what the block returns: nothing, one
value, or several, as a stage does. The block is called even with no
values, so `collect` always gives a result. It holds every value until
the end, so the whole result is in memory at once. It croaks,
`Expected a code reference`, if it's given something other than a
block or code reference. Exported by default.

See [Batching and collecting](#batching-and-collecting).

### DBIx::Squirrel::Stages::Flow

Canned stages taking or dropping values. `take` and `drop` by default,
the others upon request; all in Tooling's `:flow`.

#### drop

<!-- not run -->
```perl
drop($n)
```

Drops the first `$n` values, and passes on the rest. With `take`, it
gives a page: `drop(20), take(10)` passes on values 21 to 30. It
croaks, `Expected a count of 0 or more`, if `$n` isn't a whole number.
Exported by default.

See [Taking and dropping](#taking-and-dropping).

#### drop_if

<!-- not run -->
```perl
drop_if { ... }
drop_if(\&code)
```

Drops each value the block is true of, and passes on the rest:
`take_if`'s opposite. The block gets each value in `$_` and as its
argument. It croaks, `Expected a code reference`, if it isn't given a
block or code reference. Exported upon request.

See [Taking and dropping](#taking-and-dropping).

#### drop_while

<!-- not run -->
```perl
drop_while { ... }
drop_while(\&code)
```

Drops values while the block is true of them, then passes on the rest,
from the first it's false of. After that, the block isn't called again
on that run. The block gets each value in `$_` and as its argument. It
croaks, `Expected a code reference`, if it isn't given a block or code
reference. Exported upon request.

See [Taking and dropping](#taking-and-dropping).

#### take

<!-- not run -->
```perl
take($n)
```

Passes on the first `$n` values, then stops the run, so the statement
is finished and no more rows are fetched. The last value it passes on
goes with the stop. If there are fewer values, it passes them all on.
It croaks, `Expected a count of 0 or more`, if `$n` isn't a whole
number. Exported by default.

See [Taking and dropping](#taking-and-dropping).

#### take_first

<!-- not run -->
```perl
take_first
```

Passes on the first value, then stops the run: `take(1)`, named as the
stage of the sink `keep_first`. Exported upon request.

See [Taking and dropping](#taking-and-dropping).

#### take_if

<!-- not run -->
```perl
take_if { ... }
take_if(\&code)
```

Passes on each value the block is true of, and drops the rest, testing
every one, as `grep` does; it never stops the run. The block gets each
value in `$_` and as its argument. A plain stage ending in a test
passes on what the test returns, true or false; `take_if` passes on
the value. It croaks, `Expected a code reference`, if it isn't given a
block or code reference. Exported upon request.

See [Taking and dropping](#taking-and-dropping).

#### take_last

<!-- not run -->
```perl
take_last
```

Passes on the last value, once there are no more, reading every one to
find it; nothing if there were none. If a stage before it stops the
run, it passes on the last value to reach it. Exported upon request.

See [Taking and dropping](#taking-and-dropping).

#### take_single

<!-- not run -->
```perl
take_single
```

Passes on the one value. At a second, it warns, `Expected only one
item, but there were more`, and stops the run, so only the first goes
on: for a statement meant to give one row, whose limit was forgotten.
Exported upon request.

See [Taking and dropping](#taking-and-dropping).

#### take_while

<!-- not run -->
```perl
take_while { ... }
take_while(\&code)
```

Passes on values while the block is true of them. At the first it's
false of, it stops the run, and doesn't pass that value on. Unlike
`take_if`, it reads no further, so it suits rows in an order the test
follows. The block gets each value in `$_` and as its argument. It
croaks, `Expected a code reference`, if it isn't given a block or code
reference. Exported upon request.

See [Taking and dropping](#taking-and-dropping).

### DBIx::Squirrel::Stages::Rows

Canned stages reshaping rows. Both by default, and in Tooling's
`:rows`.

#### as_hash

<!-- not run -->
```perl
as_hash
as_hash(@names)
```

Gives each row as a hash, keyed by the column names as
`fetchrow_hashref` would key them, following `FetchHashKeyName`, so it
gives what plain DBI does. An array row, or a row object, is made into
a new hash; a hash row is passed on unchanged. As with
`fetchrow_hashref`, of two columns with the same name, the hash has
the last. Given column names, found in any case, the hash has only
those columns, keyed as it would be without them; a hash row is made
into a new hash, and a name the row hasn't got croaks, `Expected a
column of the row (age)`. It leaves the run's context as it is, so
`to_csv`, after it, takes a header of the same names. It finds the
names in the [run's context](#the-runs-context), so
it needs a statement to be what the run reads; elsewhere it croaks,
`Expected a statement to read, for the column names`. Exported by
default.

See [Reshaping rows](#reshaping-rows).

#### pluck

<!-- not run -->
```perl
pluck($name)
pluck($position)
pluck
```

Gives one column of each row, by its name, in any case, or by its
position, from 0, whether the row is an array, a hash (with the
`ekorn_slice` attribute) or a row object (from `results`). Given no
column, it gives each row's only column, counted from the row: an
array of one element, a hash of one key, a row object of one column. A
row of more columns, or of none, croaks, `Expected one column to
pluck, not 2`, rather than give the first, which would go wrong
silently when a query gains a column; `pluck(0)` gives the first. A
column the row hasn't got croaks, `Expected a column of the row
(age)`, and `pluck(undef)` or `pluck('')` croaks, `Expected a column,
by name or position`. Exported by default.

See [Reshaping rows](#reshaping-rows).

### DBIx::Squirrel::Stages::Taps

Canned stages run for their side effects. `peek` and `count_into` by
default, `dump_to` and `tee` upon request; all in Tooling's `:taps`.

#### count_into

<!-- not run -->
```perl
count_into(\$n)
```

Counts the values into `$n`, and passes them on. It sets `$n` to 0 at
the start of each run, so after a run it holds how many values went
by, even if none did. It croaks, `Expected a reference to a scalar`,
if it isn't given one. Exported by default.

See [Taps](#taps).

#### dump_to

<!-- not run -->
```perl
dump_to($fh)
dump_to
```

Writes each value to `$fh`, or to STDERR, with Data::Dumper, keys
sorted and indented by two, and passes it on. It croaks, `Expected an
open filehandle`, if `$fh` isn't one. Exported upon request.

It's for debugging. Where Text::Redact::Secrets v1.x is installed, it
writes each secret that module's rules find as `*REDACTED*`, in the
text it writes only: the value passed on is as it came. The rules find
a long, random password, token or key, such as the password in a DSN,
but not a short or ordinary password, so a dump can still hold
secrets. Without the module, or while
`local $Ekorn::Pipeline::Stages::Taps::DumpSecrets = 1` is set, it
writes each value in full; with the module there but broken, it
croaks rather than write a dump. It doesn't escape control characters
in strings, so a value from outside can send escape sequences to a
terminal.

See [Taps](#taps).

#### peek

<!-- not run -->
```perl
peek { ... }
peek(\&code)
```

Calls the block with each value, in `$_` and as its argument, and
passes the value on, whatever the block returns: for logging, or
looking. It croaks, `Expected a code reference`, if it isn't given a
block or code reference. Exported by default.

See [Taps](#taps).

#### tee

<!-- not run -->
```perl
tee(@stages)
```

Runs each value through a branch of `@stages`, for what they do on the
side, and passes the value on unchanged. What comes out of the branch
is dropped. The branch is a run of its own beside the main run, so its
stages keep their state across the values, and each main run gets a
fresh branch. A stop after the tee closes the branch, so its flushes
run. Exported upon request.

See [Taps](#taps).

### DBIx::Squirrel::Stop

Ends a pipeline early: Ekorn's `Stop`, by default.

#### Stop

<!-- not run -->
```perl
use DBIx::Squirrel::Stop;

Stop();
Stop(@values);
Ekorn::Pipeline::Stop->throw(@values);
```

Called from a stage, `Stop` ends the run early and quietly. Exported
by default.

See [Stop](#stop).

### DBIx::Squirrel::Sugar

A function for each database and statement, which runs it with the
values and stages it's given (see [The function a database is
given](#the-function-a-database-is-given) and [The function a
statement is given](#the-function-a-statement-is-given)). `use` with
`database`, `statement` or `pipeline`, and a hash of definitions after
each, defines them as the program compiles (see [Defining them on
use](#defining-them-on-use) and [The Sugar's
pipelines](#the-sugars-pipelines)).

#### database

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
when the database is first used. Each database is defined once in a
program. Its name must be one a function can have, and the package
mustn't have a function of that name already. Given by `use` with its
name.

See [Defining them as the program
runs](#defining-them-as-the-program-runs).

#### statement

<!-- not run -->
```perl
$function = statement($name, $database, $statement, @stages);
$function = statement($name, $database, $statement, \%attr, @stages);
```

Defines a statement by that name, on the database of that name. The
attributes are those to prepare it with, and the stages are its own.
It gives the calling package a function of that name, and returns the
function. The database is found when the function runs, so it can be
defined after the statement. Given by `use` with its name.

See [Defining them as the program
runs](#defining-them-as-the-program-runs).

### DBIx::Squirrel::Tooling

Exports what callers use to do work, from one place, by tags. Nothing
by default: ask for the names in the modules above, or the tags that
hold them, `:all`, `:batch`, `:context`, `:core`, `:csv`, `:flow`,
`:json`, `:rows`, `:sinks`, `:sources`, `:stages`, `:taps` and
`:words` (see
[Importing](#importing-dbixsquirreltooling)).

### DBIx::Squirrel::Util

Helpers the modules share. Internal: they may change without notice.

Pipelines, the operators, the sources, the sinks and the JSON and CSV
parts are Ekorn::Pipeline's own: `Ekorn::Pipeline`,
`Ekorn::Pipeline::Operators`, `Ekorn::Pipeline::Sources`,
`Ekorn::Pipeline::Sinks`, `Ekorn::Pipeline::JSON`,
`Ekorn::Pipeline::CSV` and `Ekorn::Pipeline::Factories`.
