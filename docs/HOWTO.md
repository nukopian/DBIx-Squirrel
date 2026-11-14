# DBIx::Squirrel user guide

<!-- stopwords: flatMap jsonb's gazetteer ORM ORMs -->

DBIx::Squirrel is the DBI, minus the boilerplate, plus a pipeline.

You keep writing SQL, and you keep the DBI: every handle is a DBI
handle, and every method you know works as it always has. What goes is
the friction around them. Placeholders can be written in whichever
style you like, a list of values can fill an `IN (...)`, and missing
values are caught before the database quietly reads them as `NULL`.
What comes in is a different way to read results: a statement becomes
a *source* of rows, and each row can go through a list of small steps,
called *stages*, written beside the query. A stage can change a row,
drop it, turn it into several, or say "that's enough", and no more
rows are fetched.

This guide shows what you can do with it, and why you might want to.
It starts at the bottom, with the DBI underneath, and works upwards a
layer at a time: statements, rows read one at a time, stages, what
comes back, and finally the shortcuts that sit on top. Each layer uses
only what the layers before it have shown, so you can read it from the
start, or go straight to the layer you need. Every example runs as it
stands, and its comments say what it prints.

[The reference](REFERENCE.md) describes every method and attribute in
full. This guide is the tour; the reference is the map.

## Contents

- [The layers, at a glance](#the-layers-at-a-glance)
- [The examples' database](#the-examples-database)
- [Import everything from one place](#import-everything-from-one-place)
- [1. Still the DBI](#1-still-the-dbi)
- [2. Writing statements](#2-writing-statements)
- [3. Binding values and running statements](#3-binding-values-and-running-statements)
- [4. A statement as a source of rows](#4-a-statement-as-a-source-of-rows)
- [5. Stages: shaping rows on the way out](#5-stages-shaping-rows-on-the-way-out)
- [6. Stopping early](#6-stopping-early)
- [7. Parts made for each run](#7-parts-made-for-each-run)
- [8. Sinks: saying what you want back](#8-sinks-saying-what-you-want-back)
- [9. Rows as objects](#9-rows-as-objects)
- [10. Building pipelines from pipelines](#10-building-pipelines-from-pipelines)
- [11. Chaining with | and @{}](#11-chaining-with--and-)
- [12. A function for each database and statement](#12-a-function-for-each-database-and-statement)
- [13. Caching and connections](#13-caching-and-connections)
- [14. Functions that take stages, and stages for others](#14-functions-that-take-stages-and-stages-for-others)
- [15. When things go wrong](#15-when-things-go-wrong)
- [16. Questions you may have](#16-questions-you-may-have)
- [17. Coming from version 1 or 2](#17-coming-from-version-1-or-2)

## The layers, at a glance

Reading a query with DBIx::Squirrel has the same shape every time.
Rows come from a statement, go through stages one at a time, and end
up somewhere:

```text
   statement  -->  stage  -->  stage  -->  stage  -->  sink
  (the rows        (change, drop, multiply,          (what you
  it fetches)       or stop: a row at a time)        get back)
```

The package is built in layers around that shape, and this guide
follows them from the bottom up:

| Layer | What it gives you | Chapter |
|---|---|---|
| The DBI | handles that are DBI handles, so nothing you know stops working | 1 |
| Statements | placeholders in any style, lists of values, SQL left as you wrote it | 2 |
| Binding and running | values checked before they reach the database; the DBI's methods, tidied | 3 |
| Iterators | a statement as a source: rows read only as they're wanted, and the handle finished for you | 4 |
| Stages | small steps beside the query, shaping each row on its way out | 5 |
| Stopping | any stage can say "enough", and no more rows are fetched | 6 |
| Parts made for each run | stages that keep a count or a batch, fresh for each run | 7 |
| Sinks | the last stage says what comes back: every row, a count, the only one | 8 |
| Row objects | rows with a method for each column, and methods of your own | 9 |
| Composition | pipelines inside pipelines, named once and used anywhere | 10 |
| Operators | `statement \| stage \| sink`, for when a query reads best as one line | 11 |
| Sugar | a function for each database and each statement | 12 |

Above them sit caching and connections (chapter 13), and your own
functions and stages (chapter 14). Chapter 15 covers errors, chapter
16 answers the questions people ask first, including how fast it is,
and chapter 17 is for code written for earlier versions.

The pipeline itself, the stages, stopping and sinks, comes from
[Ekorn::Pipeline](https://github.com/nukopian/Ekorn-Pipeline), a
distribution of its own that began life inside DBIx::Squirrel. You
don't need to know it to use DBIx::Squirrel: this guide shows its
parts as they apply to rows. Its [user
guide](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/HOWTO.md)
has the general case, for values from anywhere.

## The examples' database

Every example runs against this small SQLite database, a file called
`music.db`, made here. The examples follow on from each other, so
`$dbh` is this handle wherever it appears. Nothing in the guide
changes the data for good: an example that writes rolls its change
back, so what each example prints is what you'll see. It imports every
stage, sink and word the guide uses, from DBIx::Squirrel::Tooling, so
the examples needn't (see [Import everything from one
place](#import-everything-from-one-place)).

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

Three artists, four albums and six tracks: small enough to keep in
your head, big enough to show every feature.

## Import everything from one place

What you use to do work with DBIx::Squirrel is made in several
modules, one for each kind of thing, and the chapters below say which.
You needn't remember them: DBIx::Squirrel::Tooling exports all of it,
by the same tags as Ekorn::Pipeline::Tooling, with two of
DBIx::Squirrel's own:

| Tag | What it gives you | Made in |
|---|---|---|
| `:core` | `Stop` and `gather` | DBIx::Squirrel::Stop and ::Gather |
| `:flow` | `take`, `drop`, `take_if`, `take_while` and the rest | DBIx::Squirrel::Stages::Flow |
| `:batch` | `batch` and `collect` | DBIx::Squirrel::Stages::Batch |
| `:taps` | `peek`, `count_into` and `dump_to` | DBIx::Squirrel::Stages::Taps |
| `:rows` | `pluck` and `as_hash` | DBIx::Squirrel::Stages::Rows |
| `:stages` | `:flow`, `:batch`, `:taps` and `:rows` | |
| `:context` | `iterator`, `result_number` and `result_original` | DBIx::Squirrel::Context |
| `:sources` | `from_array`, `from_file`, `from_fh` and `counter` | Ekorn::Pipeline::Sources |
| `:sinks` | `count_items`, `keep_all`, `keep_first`, `to_file` and the rest | Ekorn::Pipeline::Sinks |
| `:words` | `pipeline`, `stage`, `source`, `generator`, `sink_one` and the rest | Ekorn::Pipeline::Factories |
| `:all` | all of the above | |

Ask for what you need, by tag or by name. Nothing comes by default:

```perl
package My::Report {
    use DBIx::Squirrel::Tooling qw(:stages :sinks);
    say $dbh->iterate(
        'SELECT name, plays FROM track',
        take_if { $_->[1] > 6000 },
        count_items,
    );
    # 3
}
```

Each name is the very sub its own module exports, so it makes no
difference which you import it from, and where DBIx::Squirrel and
Ekorn::Pipeline both export a name, it's the same sub. Three things
Tooling leaves out: what's for extending DBIx::Squirrel rather than
using it, such as `croakf`, which you import from its own module when
chapter 14 needs it; the Sugar, whose `use` makes functions for your
databases and statements, as chapter 12 explains; and `|`, which only
`use Ekorn::Pipeline::Operators` puts in force, in its own scope, as
chapter 11 explains.

## 1. Still the DBI

DBIx::Squirrel is a subclass of the DBI. That one decision shapes the
rest: a DBIx::Squirrel handle *is* a DBI handle, so it goes wherever
one goes, and every method, attribute and driver you already know
works on it. Where DBIx::Squirrel and plain DBI do the same thing,
they give the same result. Plain DBI is the baseline, and
DBIx::Squirrel only adds.

So you can bring it into an existing program one query at a time, and
anything you can't find in this guide, the DBI's own documentation
covers.

### Connect to a database

`connect` takes what the DBI's `connect` takes. The one difference is
that it always croaks if it can't connect, so there's no `or die` to
remember:

<!-- not run -->
```perl
my $pg    = DBIx::Squirrel->connect('dbi:Pg:dbname=music', $user, $pass, {RaiseError => 1});
my $mysql = DBIx::Squirrel->connect('dbi:mysql:database=music', $user, $pass);
```

With no username or password, as with SQLite, the attributes can come
straight after the data source:

```perl
my $music = DBIx::Squirrel->connect('dbi:SQLite:dbname=music.db', {RaiseError => 1});
say ref $music;    # DBIx::Squirrel::db
```

### Check it's still a DBI handle

The handles are the DBI's classes, extended. Code that checks for a
DBI handle, or takes one, takes these:

```perl
say $dbh->isa('DBI::db') ? 'a DBI database handle' : 'something else';    # a DBI database handle

my $sth = $dbh->prepare('SELECT name FROM artist WHERE id = ?');
say $sth->isa('DBI::st') ? 'a DBI statement handle' : 'something else';    # a DBI statement handle

$sth->execute(1);
say $sth->fetchrow_arrayref->[0];    # Abba
```

### Use a handle you already have

Code that already has a plain DBI handle can get a DBIx::Squirrel one
with the same connection details. It's a new connection, not a second
name for the old one, so the two don't share transactions:

```perl
use DBI;

my $plain    = DBI->connect('dbi:SQLite:dbname=music.db', '', '', {RaiseError => 1});
my $squirrel = DBIx::Squirrel->connect($plain);

say ref $squirrel;    # DBIx::Squirrel::db
```

### Use the DBI's transactions and methods

Transactions, `last_insert_id`, `quote` and the rest are the DBI's,
and work as they always have. Here an artist is added, counted, and
taken away again:

```perl
$dbh->begin_work;
$dbh->do('INSERT INTO artist (name) VALUES (?)', 'Dido');
say $dbh->last_insert_id;                                    # 4
say $dbh->selectrow_array('SELECT COUNT(*) FROM artist');    # 4
$dbh->rollback;
say $dbh->selectrow_array('SELECT COUNT(*) FROM artist');    # 3

say $dbh->quote("it's");    # 'it''s'
```

### Import the DBI's constants

`use DBIx::Squirrel` takes whatever `use DBI` takes:

```perl
use DBIx::Squirrel qw(:sql_types);

say SQL_INTEGER;    # 4
```

### Set defaults for every statement

Attributes starting `ekorn_` are DBIx::Squirrel's own. Given to
`connect`, they're the defaults for every statement the handle
prepares. With `ekorn_slice => {}`, every row that DBIx::Squirrel
reads for you comes as a hash, keyed by column name:

```perl
my $hashes = DBIx::Squirrel->connect('dbi:SQLite:dbname=music.db', {
    RaiseError  => 1,
    ekorn_slice => {},
});

say $hashes->iterate('SELECT name FROM artist WHERE id = 1')->first->{name};    # Abba
```

`iterate` and `first` come in [chapter
4](#4-a-statement-as-a-source-of-rows).

### Give the handles methods of your own

Subclass DBIx::Squirrel as you'd subclass the DBI: a class to connect
with, and a database handle class and a statement handle class beside
it, each a subclass of DBIx::Squirrel's. `connect`, called on your
class, gives you your handles:

```perl
package My::Squirrel     { our @ISA = 'DBIx::Squirrel' }
package My::Squirrel::st { our @ISA = 'DBIx::Squirrel::st' }

package My::Squirrel::db {
    our @ISA = 'DBIx::Squirrel::db';

    sub artist_names ($self) {
        return $self->iterate('SELECT name FROM artist ORDER BY id', sub { $_->[0] })->all;
    }
}

my $mine = My::Squirrel->connect('dbi:SQLite:dbname=music.db', {RaiseError => 1});
say join ' ', $mine->artist_names;    # Abba Blur Cream
```

Give both handle classes. Without them, the DBI warns, and gives you
its own handles.

## 2. Writing statements

The DBI understands one kind of placeholder, `?`, and leaves you to
count them. DBIx::Squirrel reads your statement first, finds its
placeholders in whatever style you wrote them, and hands the DBI the
`?`s it expects. The SQL is otherwise left exactly as you wrote it.

### Use the placeholder style you like

Each of these is the same query. A statement uses one style
throughout. The named ones take their values as pairs, the others in
order:

```perl
my @styles = (
    'SELECT title FROM album WHERE year = ?',
    'SELECT title FROM album WHERE year = ?1',
    'SELECT title FROM album WHERE year = :1',
    'SELECT title FROM album WHERE year = $1',
    'SELECT title FROM album WHERE year = :year',
    'SELECT title FROM album WHERE year = $year',
);
for my $sql (@styles) {
    my $sth = $dbh->prepare($sql);
    $sth->execute($sql =~ m( [:\$] year )x ? (year => 1994) : 1994);
    say $sth->fetchrow_arrayref->[0];
}
# Parklife
# Parklife
# Parklife
# Parklife
# Parklife
# Parklife
```

So a statement copied from PostgreSQL's documentation (`$1`), Oracle's
(`:name`) or SQLite's (`?1`) runs as it stands, on any driver.

### Use one value in several places

A numbered placeholder takes its value once, wherever it appears. With
plain `?`s you'd pass the same value twice, and keep the two in step:

```perl
my $near = $dbh->selectcol_arrayref(
    'SELECT title FROM album WHERE year BETWEEN $1 - 1 AND $1 + 1 ORDER BY year',
    undef, 1995,
);
say "@$near";    # Parklife The Great Escape
```

A named placeholder does the same, wherever its name appears.

### Match any of a list of values

Put `...` in front of a placeholder, and give it an array reference.
It's written as a `?` for each value:

```perl
my $titles = $dbh->selectcol_arrayref(
    'SELECT title FROM album WHERE year IN (...:years) ORDER BY year',
    years => [1967, 1994],
);
say "@$titles";    # Disraeli Gears Parklife

my $names = $dbh->selectcol_arrayref('SELECT name FROM artist WHERE id IN (...?)', [1, 3]);
say "@$names";     # Abba Cream
```

Without it, you'd write `join ', ', ('?') x @ids` into the SQL
yourself. The statement is prepared for the number of values, so give
them with it: to `do`, a select method, `iterate` or `results`.
`prepare` alone croaks, as it has no values yet. An empty list croaks
too, as `IN ()` isn't SQL, so check for one first.

### Write a long statement over several lines

Give the lines in an array reference, and they're joined with spaces.
No string concatenation, and no missing space at the end of a line:

```perl
my $sth = $dbh->prepare([
    'SELECT title',
    'FROM album',
    'WHERE year < :year',
    'ORDER BY year',
]);
$sth->execute(year => 1990);
say $_->[0] for @{ $sth->fetchall_arrayref };
# Disraeli Gears
# Arrival
```

### Keep quotes, comments and casts as they are

Placeholders are looked for only in the SQL itself, not in strings or
comments, so none of this needs escaping:

```perl
my $row = $dbh->selectrow_arrayref(
    q{SELECT '10:30', :name -- not :a placeholder},
    undef, name => 'Abba',
);
say "@$row";    # 10:30 Abba
```

On PostgreSQL, put a backslash in front of a `?`, `:` or `$` that's an
operator, such as jsonb's `?`:

<!-- not run -->
```perl
my $sth = $pg->prepare(q{SELECT * FROM doc WHERE data \? 'key' AND id = :id});
```

Strings and comments are read by the rules of the handle's database:
MySQL's allow a backslash before a quote, and take `#` as a comment.
Through DBD::ODBC or DBD::Proxy, DBIx::Squirrel asks the database what
it is. When it can't tell, or to read one statement by another
database's rules, name the rules with `ekorn_dialect`:

<!-- not run -->
```perl
my $odbc = DBIx::Squirrel->connect($odbc_dsn, $user, $pass, {ekorn_dialect => 'mysql'});
my $sth  = $dbh->prepare(q{SELECT 'it\'s :not a placeholder', :id}, {ekorn_dialect => 'mysql'});
```

DBD::Pg's own `pg_placeholder_dollaronly` and
`pg_placeholder_nocolons` are followed too, on the handle or given to
`prepare`.

## 3. Binding values and running statements

### Give named values as pairs or a hash

As pairs, or in a hash reference, with or without the sigil:

```perl
my $sth = $dbh->prepare('SELECT title FROM album WHERE artist_id = :artist AND year >= :year');

$sth->execute(artist => 2, year => 1995);
say $sth->fetchrow_arrayref->[0];    # The Great Escape

$sth->execute({':artist' => 2, ':year' => 1995});
say $sth->fetchrow_arrayref->[0];    # The Great Escape
```

### Give the values in an array reference

A single array reference stands for the values in it. That's handy
when the values arrive as one:

```perl
my @values = (2, 1995);
my $sth    = $dbh->prepare('SELECT title FROM album WHERE artist_id = ? AND year = ?');
$sth->execute(\@values);
say $sth->fetchrow_arrayref->[0];    # The Great Escape
```

With DBD::Pg, an array reference given to a statement taking a single
value is a PostgreSQL array, as it is with the DBI.

### Bind first, execute later

`bind` takes values as `execute` does, and returns the handle, so the
two can be chained. `bind_param` takes a placeholder's name or number,
and a type if you need one, and binds every use of it:

```perl
use DBIx::Squirrel qw(:sql_types);

my $sth = $dbh->prepare('SELECT name FROM track WHERE plays > :plays ORDER BY plays DESC');
$sth->bind(plays => 7000)->execute;
say $_->[0] for @{ $sth->fetchall_arrayref };
# Dancing Queen
# Sunshine of Your Love

$sth->bind_param(':plays', 8000, SQL_INTEGER);
$sth->execute;
say $sth->fetchrow_arrayref->[0];    # Dancing Queen
```

### Let mistakes in the values be caught

Give a statement the wrong values, and it croaks at your line, saying
which placeholder went without. Plain DBI would run the query with the
missing value as `NULL`, and quietly find nothing:

```perl
my $sth = $dbh->prepare('SELECT name FROM artist WHERE id = :id AND name = :name');
eval { $sth->execute(id => 1) };
print $@;    # Expected a value for each placeholder (none for name) at ... line ...
```

### Change rows with `do`

`do` takes the bind values straight after the statement, without the
`undef` the DBI wants for the attributes in between. It returns the
number of rows changed:

```perl
$dbh->begin_work;
my $rows = $dbh->do('UPDATE track SET plays = plays + 1 WHERE album_id = :album', album => 1);
say $rows;    # 2
$dbh->rollback;
```

The attributes can still be given, as a hash reference, or `undef`,
straight after the statement. Only a hash reference or `undef` there
is taken for them, so named values given in a hash reference need the
attributes, or `undef`, in front.

### Fetch with the select methods

The DBI's select methods work as they do with the DBI, with
placeholders in any style, and the attributes left out when there are
none:

```perl
my($title, $year) = $dbh->selectrow_array('SELECT title, year FROM album WHERE id = ?', 2);
say "$title ($year)";    # Parklife (1994)

my $artist = $dbh->selectrow_hashref('SELECT * FROM artist WHERE id = :id', id => 2);
say $artist->{name};    # Blur

my $titles = $dbh->selectcol_arrayref('SELECT title FROM album WHERE artist_id = $1', 2);
say "@$titles";    # Parklife The Great Escape

my $rows = $dbh->selectall_arrayref('SELECT name, plays FROM track WHERE plays >= ?1 ORDER BY plays DESC', 7000);
say join ', ', map {"$_->[0] ($_->[1])"} @$rows;    # Dancing Queen (9100), Sunshine of Your Love (7700)

my $by_id = $dbh->selectall_hashref('SELECT id, name FROM artist', 'id');
say $by_id->{3}{name};    # Cream
```

Each also takes a statement handle, prepared once, in place of the
SQL:

```perl
my $sth = $dbh->prepare('SELECT name FROM track WHERE album_id = :album ORDER BY name');
say join ', ', @{ $dbh->selectcol_arrayref($sth, album => 2) };    # Girls & Boys, Parklife
say join ', ', @{ $dbh->selectcol_arrayref($sth, album => 1) };    # Dancing Queen, Knowing Me, Knowing You
```

### Send what a select method gives through stages

Give a select method stages after its values, and what the DBI's
method returns is sent through them, and what comes out of the last
one comes back. Stages come into their own in [chapter
5](#5-stages-shaping-rows-on-the-way-out); here's a first taste.
`selectall_array` gives the rows, so each row goes through the stages
in turn:

```perl
my @names = $dbh->selectall_array(
    'SELECT name FROM artist ORDER BY name',
    sub ($row) { $row->[0] },    # each row, into its name
    sub { uc },                  # each name, in capitals
);
say "@names";    # ABBA BLUR CREAM
```

The others give one value, a reference, so their first stage gets
that: `selectall_arrayref`'s array of rows, say, which a stage can
turn into names all at once:

```perl
my @names = $dbh->selectall_arrayref('SELECT name FROM artist ORDER BY name', sub ($rows) { map { $_->[0] } @$rows });
say "@names";    # Abba Blur Cream
```

`selectrow_array` gives the row's values, one at a time. Asked for one
value, a call with stages gives how many came out, unless its last
stage is a sink, which [chapter 8](#8-sinks-saying-what-you-want-back)
explains. Without stages, each method gives exactly what the DBI's
does.

### Finish an active statement before running it again

A statement executed again while it still has rows to read is left to
the driver to deal with. With `ekorn_finish_active`, it's finished
first:

```perl
my $sth = $dbh->prepare('SELECT name FROM artist ORDER BY id', {ekorn_finish_active => 1});
$sth->execute;
$sth->fetchrow_arrayref;
$sth->execute;
say $sth->fetchrow_arrayref->[0];    # Abba
```

## 4. A statement as a source of rows

Here's where DBIx::Squirrel parts company with the DBI's way of
reading. With the DBI, you choose up front: fetch every row at once,
with `selectall_arrayref`, and hold them all; or loop over
`fetchrow_arrayref`, and remember to `finish` the statement if you
leave early.

DBIx::Squirrel's `iterate` gives you an *iterator*: a statement
treated as a source of rows, read only as the rows are wanted. You ask
for the next row, or the first, or the only one, or all of them, and
it fetches what that takes, and no more. When you're done, or when the
iterator goes out of scope, the statement is finished for you.

### Loop over the rows

```perl
my $it = $dbh->iterate('SELECT name FROM artist ORDER BY name');
while (my($row) = $it->next) {
    say $row->[0];
}
# Abba
# Blur
# Cream
```

Read `next` in list context, as here. It returns an empty list at the
end, so a row that happens to be `undef`, or a false value from a
stage, is never taken for the end.

`iterate` takes the statement, then its values, as `do` does. It's on
statement handles too, which makes one statement easy to run for
several values:

```perl
my $sth = $dbh->prepare('SELECT title FROM album WHERE artist_id = ? ORDER BY year');
for my $artist_id (1, 2) {
    my $it = $sth->iterate($artist_id);
    while (my($row) = $it->next) {
        say "$artist_id: $row->[0]";
    }
}
# 1: Arrival
# 2: Parklife
# 2: The Great Escape
```

### Leave when you've had enough

Leaving a loop early never reads the rest. The statement is finished
when the iterator goes:

```perl
my $it = $dbh->iterate('SELECT name FROM track ORDER BY plays DESC');
my $n  = 0;
while (my($row) = $it->next) {
    say $row->[0];
    last if ++$n == 2;
}
# Dancing Queen
# Sunshine of Your Love
```

Behind the scenes, rows are fetched a few at a time: 2 at first, then
twice as many each time a batch is used up, up to 64. So a short read
fetches very little, and a long one doesn't make a trip to the
database for every row, or hold the whole result in memory.

### Take the first row, or the only one

`first` gives the next row, or `undef` if there's none, and finishes
the statement. It fetches two rows at most:

```perl
my $top = $dbh->iterate('SELECT name FROM track ORDER BY plays DESC')->first;
say $top->[0];    # Dancing Queen
```

`single` is for a query that should find one row. It gives the row, or
`undef` if there's none. If there's a second, it warns "Expected only
one item, but there were more", and gives the first: the statement may
have lost its `LIMIT 1`, or its `WHERE` may match more than you
thought. It reads only as far as the second row to know:

```perl
my $total = $dbh->iterate('SELECT SUM(plays) FROM track')->single;
say $total->[0];    # 36800

my $warning = '';
local $SIG{__WARN__} = sub ($message) { $warning = $message };
my $abba = $dbh->iterate('SELECT name FROM artist ORDER BY id')->single;
say $abba->[0];    # Abba
print $warning;    # Expected only one item, but there were more at ... line ...
```

### Get every row at once

`all` gives every row still to come, as a list; or, where one value is
asked for, as an array reference. It's never a count: for that, see
`count_items` in [chapter 8](#8-sinks-saying-what-you-want-back).

```perl
my @rows = $dbh->iterate('SELECT name FROM artist ORDER BY id')->all;
my $rows = $dbh->iterate('SELECT name FROM artist ORDER BY id')->all;

say scalar @rows;          # 3
say $rows->[2][0];         # Cream
```

After `next`, `all` gives the rest. With no stages, it fetches the
rest of the rows in one go, which is about as quick as the DBI's own
`selectall_arrayref`.

### Fetch rows as hashes

Rows come as arrays unless you ask otherwise. Give `ekorn_slice` to
`connect`, `prepare` or `iterate` to have them as hashes:

```perl
my $it = $dbh->iterate('SELECT id, name FROM artist ORDER BY id', {ekorn_slice => {}});
while (my($row) = $it->next) {
    say "$row->{id}: $row->{name}";
}
# 1: Abba
# 2: Blur
# 3: Cream
```

### Find the column names

`column_names` gives the statement's columns, as `fetchrow_hashref`
would key them:

```perl
my $it = $dbh->iterate('SELECT id, title AS Album FROM album');
say join ', ', $it->column_names;    # id, Album
```

### Start again from the top

`reset` runs the statement again, from the first row. Values given to
`reset` replace the ones given before:

```perl
my $it = $dbh->iterate('SELECT name FROM artist WHERE id > ? ORDER BY id', 0);
say scalar $it->all->@*;              # 3
say scalar $it->reset(1)->all->@*;    # 2
```

### Ask how the run ended

Each time the statement runs, from the first row until it's finished,
is a *run*. `ended` says how the last one ended: `done` if the rows
ran out, `stopped` if it was cut short, by `first`, `single` or a
stage, and `died` if a stage died. While a run is going, it says
nothing:

```perl
my $it = $dbh->iterate('SELECT name FROM artist');
$it->next;
say $it->ended // 'still going';    # still going
$it->all;
say $it->ended;                     # done
$it->reset->first;
say $it->ended;                     # stopped
```

### Use one iterator at a time on a statement handle

A statement handle runs one statement at a time. While one iterator
has rows left to read, another on the same handle croaks rather than
take the handle from under it. Read the first to the end, or let it
go:

```perl
my $sth = $dbh->prepare('SELECT name FROM artist ORDER BY id');
my $one = $sth->iterate;
my $two = $sth->iterate;
$one->next;
eval { $two->next };
print $@;    # Expected the statement handle's other iterator to be finished at ... line ...

$one->all;
say $two->next->[0];    # Abba
```

### Compared with fetching in a loop

| You want | With the DBI | With an iterator |
|---|---|---|
| every row | `selectall_arrayref`, or a loop | `all` |
| some rows, then stop | a loop, a counter, and `finish` | `next` and `last`; the statement is finished for you |
| the first row | `selectrow_arrayref`, which reads it and finishes | `first`, which reads at most two rows |
| exactly one row | a loop that checks for a second | `single`, which warns at a second |
| memory | `selectall_*` holds every row | a few rows at a time, up to 64 |

The iterator's real strength shows in the next chapter: whatever you'd
do to each row in the loop can go beside the query instead, as stages.

## 5. Stages: shaping rows on the way out

A *stage* is a sub that's given one row, and returns what should go
on: the row changed, nothing at all, or several values in its place.
Give `iterate` stages after its values, and each row goes through them
in order. What comes out of the last stage is what you read.

That's all a stage is. It's an ordinary sub, so anything Perl can do,
a stage can do, and it's tested like any sub. The stages and the
machinery that runs them come from Ekorn::Pipeline; DBIx::Squirrel
feeds them rows, and adds stages of its own that know about rows.

### Change each row

Return one value, and it takes the row's place. A stage gets its value
as its argument, and in `$_`, so write whichever reads best:

```perl
my @titles = $dbh->iterate('SELECT title, year FROM album ORDER BY year', sub ($row) { "$row->[0] ($row->[1])" })->all;
say for @titles;
# Disraeli Gears (1967)
# Arrival (1976)
# Parklife (1994)
# The Great Escape (1995)

my @names = $dbh->iterate('SELECT name FROM artist ORDER BY id', sub { $_->[0] })->all;
say "@names";    # Abba Blur Cream
```

### Leave rows out

Return an empty list, and the row is dropped:

```perl
my @hits = $dbh->iterate(
    'SELECT name, plays FROM track ORDER BY id',
    sub { $_->[1] >= 6000 ? $_ : () },    # keep the popular ones
    sub { $_->[0] },                      # then just the name
)->all;
say join ', ', @hits;    # Dancing Queen, Girls & Boys, Sunshine of Your Love
```

That's a filter in Perl, and `take_if`, from
DBIx::Squirrel::Stages::Flow, says the same in a word:
`take_if { $_->[1] >= 6000 }` passes on each row its block is true of,
and `drop_if` each it's false of ([chapter
6](#keep-or-drop-rows-by-a-test)). When the database can do it, in a
`WHERE`, let it: it's quicker, and fewer rows cross the wire. A stage
is for what SQL can't say, or can't say well: a regular expression, a
lookup in a hash, a call to some other code.

### Turn one row into several

Return a list, and each value goes on, in turn, through the stages
after:

```perl
my @words = $dbh->iterate(
    'SELECT title FROM album ORDER BY year',
    sub { split ' ', $_->[0] },    # each title, into its words
    sub { lc },                    # each word, in lower case
)->all;
say "@words";    # disraeli gears arrival parklife the great escape
```

Changing, dropping and multiplying are the three things stages do, and
they combine freely. In other languages they're map, filter and
flatMap; here they're all just a sub, returning one value, none, or
several.

### Pick out a column, or make each row a hash

`pluck` and `as_hash`, from DBIx::Squirrel::Stages::Rows, are stages
that know about rows. `pluck` gives one column, by its name, in any
case, or its position, from 0. `as_hash` gives each row as a hash, as
`fetchrow_hashref` would:

```perl
my @titles = $dbh->iterate('SELECT title, year FROM album ORDER BY year', pluck('title'))->all;
say "@titles";    # Disraeli Gears Arrival Parklife The Great Escape

my $album = $dbh->iterate('SELECT title, year FROM album WHERE id = 2', as_hash)->first;
say "$album->{title} ($album->{year})";    # Parklife (1994)
```

They work whatever shape the rows come in: arrays, hashes, or the row
objects of [chapter 9](#9-rows-as-objects). To find a name's place in
an array, they ask the statement for its column names, as the rows go
by.

That has a catch. The column names are the statement's, not the row's.
After a stage that reshapes the rows, `pluck` by name still looks in
the statement's place for the column, and finds whatever's there now,
without a word. Make the rows hashes first, and `pluck` by name reads
each hash's own keys, however a stage has changed them:

```perl
my @wrong = $dbh->iterate(
    'SELECT id, name FROM artist ORDER BY id',
    sub { [reverse @$_] },
    pluck('id'),
)->all;
say "@wrong";    # Abba Blur Cream

my @right = $dbh->iterate(
    'SELECT id, name FROM artist ORDER BY id',
    as_hash,
    sub { +{%$_, name => uc $_->{name}} },
    pluck('id'),
)->all;
say "@right";    # 1 2 3
```

The `+` in `+{...}` tells Perl the braces are a hash, not a block.

### Ask which result you're making, and from which row

DBIx::Squirrel::Context answers questions a stage can't answer from
its value alone. `result_number` is the number of the result being
made, from 1. `result_original` is the row it's being made from, as it
was fetched, whatever the stages before have done to it:

```perl
my @chart = $dbh->iterate(
    'SELECT name, plays FROM track ORDER BY plays DESC',
    pluck('name'),
    sub { result_number() . ". $_ (" . result_original()->[1] . ' plays)' },
)->all;
say for @chart[0, 1];
# 1. Dancing Queen (9100 plays)
# 2. Sunshine of Your Love (7700 plays)
```

`result_number` counts results, not rows, so a dropped row doesn't use
up a number.

### Watch rows go by, or count them

`peek` and `count_into`, from DBIx::Squirrel::Stages::Taps, look at
each value as it passes, and pass it on unchanged. They're how you see
what a pipeline is doing:

```perl
my $seen  = 0;
my @names = $dbh->iterate(
    'SELECT name FROM artist ORDER BY name',
    count_into(\$seen),
    pluck('name'),
    peek { say "passing $_" },
)->all;
say "@names, from $seen rows";
# passing Abba
# passing Blur
# passing Cream
# Abba Blur Cream, from 3 rows
```

`dump_to`, from the same module on request, writes each value with
Data::Dumper, to STDERR or a filehandle you give: handy while you
debug, and to be taken out before the code goes live.

### Compared with `map` over every row

The obvious alternative is to fetch every row and use Perl's own `map`
and `grep`:

```perl
my @hits = map { $_->[0] } grep { $_->[1] >= 6000 }
    @{ $dbh->selectall_arrayref('SELECT name, plays FROM track ORDER BY id') };
say join ', ', @hits;    # Dancing Queen, Girls & Boys, Sunshine of Your Love
```

For a small result that's read in full, that's fine, and it's quicker:
[chapter 16](#16-questions-you-may-have) has the numbers. Stages earn
their keep when:

- **you may not need every row,** as a stage can stop the reading
  early ([chapter 6](#6-stopping-early)), so the rest are never
  fetched;
- **the result is large,** as rows go through a few at a time, never
  all held at once;
- **the steps should travel with the query,** given to a function, or
  kept with a named statement ([chapter
  12](#12-a-function-for-each-database-and-statement));
- **the steps are worth reusing,** as a stage or a pipeline made once
  goes wherever stages go ([chapter
  10](#10-building-pipelines-from-pipelines)).

## 6. Stopping early

A stage can say "that's enough". The run stops there: the rows already
through are kept, nothing else is processed, and no more rows are
fetched from the database.

### Stop from a stage

`Stop`, from DBIx::Squirrel::Stop, ends the run. Values given to it go
on through the stages after it, as the last ones:

```perl
my @upto = $dbh->iterate(
    'SELECT title, year FROM album ORDER BY year',
    sub { $_->[1] >= 1990 ? Stop($_) : $_ },    # this one, then no more
    sub { $_->[0] },
)->all;
say "@upto";    # Disraeli Gears Arrival Parklife
```

### Take the first few, or skip some

`take` and `drop`, from DBIx::Squirrel::Stages::Flow, pass on, or pass
over, a number of values. `take` stops the run once it has its values,
so no more rows are fetched:

```perl
my @page = $dbh->iterate(
    'SELECT name FROM track ORDER BY id',
    sub { $_->[0] },
    sub { m( \s )x ? $_ : () },    # names of more than one word
    drop(1),                       # the second and third of them
    take(2),
)->all;
say for @page;
# Knowing Me, Knowing You
# Girls & Boys
```

### Keep or drop rows by a test

`take_if` passes on each value its block is true of, and `drop_if`
each it's false of. They test every value, as Perl's `grep` does, and
never stop the run, unlike `take_while`, which stops at the first
value its test fails:

```perl
my @popular = $dbh->iterate(
    'SELECT name, plays FROM track ORDER BY id',
    take_if { $_->[1] > 6000 },
    sub { $_->[0] },
)->all;
say join ', ', @popular;    # Dancing Queen, Girls & Boys, Sunshine of Your Love

my @quiet = $dbh->iterate(
    'SELECT name, plays FROM track ORDER BY id',
    drop_if { $_->[1] > 6000 },
    sub { $_->[0] },
)->all;
say join ', ', @quiet;    # Knowing Me, Knowing You, Parklife, Country House

my @until = $dbh->iterate(
    'SELECT name, plays FROM track ORDER BY id',
    take_while { $_->[1] > 6000 },
    sub { $_->[0] },
)->all;
say join ', ', @until;    # Dancing Queen
```

The last stops at Knowing Me, Knowing You, the first track that fails
its test, so the tracks after it are never fetched.

### Take while a test holds, or skip until it fails

`take_while` passes values on while its block is true of them, and
stops at the first it isn't. `drop_while` passes over values while its
block is true, then passes on the rest:

```perl
my @hits = $dbh->iterate(
    'SELECT name, plays FROM track ORDER BY plays DESC',
    take_while { $_->[1] > 6000 },
    sub { $_->[0] },
)->all;
say join ', ', @hits;    # Dancing Queen, Sunshine of Your Love, Girls & Boys

my @later = $dbh->iterate(
    'SELECT title, year FROM album ORDER BY year',
    drop_while { $_->[1] < 1990 },
    sub { $_->[0] },
)->all;
say join ', ', @later;    # Parklife, The Great Escape
```

### Take the first, the last, or the only one, and go on

`take_first`, `take_last` and `take_single` pass on one value, and let
the stages after them go on working with it. `take_single` warns at a
second value, as `single` does:

```perl
my @oldest = $dbh->iterate(
    'SELECT title FROM album ORDER BY year',
    take_first,
    sub { uc $_->[0] },
)->all;
say "@oldest";    # DISRAELI GEARS

my @newest = $dbh->iterate(
    'SELECT title FROM album ORDER BY year',
    take_last,
    sub { lc $_->[0] },
)->all;
say "@newest";    # the great escape
```

### Catch errors in a stage, but let a stop through

A stop works by throwing an exception that the pipeline catches. So a
stage that catches errors itself must pass a stop on, or the run won't
stop. A stop is always an Ekorn::Pipeline::Stop:

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

### Compared with `LIMIT` and `last`

`LIMIT 2` in the SQL is the best way to take two rows: the database
does the work, and sends only two. `take` is for when Perl decides,
not the database: the first two whose names pass a regular expression,
the rows until a running total reaches some amount. A `last` in a loop
does the same job, but only in that loop; a stage can be handed to a
function, or kept with a named statement, and still stop the reading
there.

## 7. Parts made for each run

A plain stage that keeps a count in a closure keeps it from one run to
the next:

```perl
my $count = 0;
my $numbered = sub { ++$count . ". $_->[0]" };

my $it = $dbh->iterate('SELECT name FROM artist ORDER BY id', $numbered);
say join ', ', $it->all;           # 1. Abba, 2. Blur, 3. Cream
say join ', ', $it->reset->all;    # 4. Abba, 5. Blur, 6. Cream
```

Sometimes that's what you want. Usually it isn't. And some stages need
more than a fresh start: one that hands rows on in batches has to know
when the rows have run out, to hand on the last, short batch.

### Keep state for one run with `gather`

`gather`, from DBIx::Squirrel::Gather, makes a stage afresh at the
start of each run. Its block is called then, so whatever it declares
is new each time, and it returns the stage:

```perl
my $it = $dbh->iterate(
    'SELECT name FROM artist ORDER BY id',
    gather {
        my $count = 0;    # this run's
        return sub { ++$count . ". $_->[0]" };
    },
);
say join ', ', $it->all;           # 1. Abba, 2. Blur, 3. Cream
say join ', ', $it->reset->all;    # 1. Abba, 2. Blur, 3. Cream
```

A run starts each time the statement runs: when an iterator is first
read, and after each `reset`.

### Hand over what you held when the rows run out

The block can return a *flush* after the stage. It's called once the
rows run out, even if there were none, and what it returns goes on
through the stages after, as if a stage had returned it:

```perl
# Each value, then, once they run out, how many there were
sub and_count () {
    return gather {
        my $count = 0;
        return (
            sub ($value) { $count++; $value },
            sub ()       {"($count)"},
        );
    };
}

my @lines = $dbh->iterate('SELECT name FROM artist ORDER BY name', sub { $_->[0] }, and_count)->all;
say "@lines";    # Abba Blur Cream (3)
```

### Clean up however the run ends

After the flush, the block can return an *end*. It's called once the
run is over, however it ended, and told how: `done`, `stopped` or
`died`. It's the place to release what the stage holds, or to note
what happened. What it returns is dropped.

The parts can also be returned by name, in a hash reference, giving
only those you have:

```perl
my @how;
my $watched = gather {
    return {
        step => sub { $_->[0] },
        end  => sub ($how) { push @how, $how },
    };
};

my $it = $dbh->iterate('SELECT name FROM artist ORDER BY id', $watched);
$it->all;
$it->reset->first;
say "@how";    # done stopped
```

### Hand rows on in batches, or all at once

`batch` and `collect`, from DBIx::Squirrel::Stages::Batch, are made
with `gather`. `batch` passes values on in arrays of a size you give,
the last when the rows run out. `collect` holds every value, and once
they run out, passes on what its block makes of them, or an array of
them:

```perl
my $batches = $dbh->iterate(
    'SELECT name FROM track ORDER BY id',
    pluck('name'),
    batch(4),
);
while (my($batch) = $batches->next) {
    say scalar(@$batch), ': ', join ', ', @$batch;
}
# 4: Dancing Queen, Knowing Me, Knowing You, Girls & Boys, Parklife
# 2: Country House, Sunshine of Your Love

my $line = $dbh->iterate(
    'SELECT name FROM artist ORDER BY name',
    pluck('name'),
    collect { join ', ', @_ },
)->first;
say $line;    # Abba, Blur, Cream
```

`batch` is the way to write rows somewhere a few hundred at a time,
such as an API that takes them in bulk, without holding every row.

### Choose the stages for each run

The stage a `gather` block returns can be a whole pipeline, built for
the run. So the block can choose its stages as each run starts:

```perl
use Ekorn::Pipeline;

my $it = $dbh->iterate(
    'SELECT name FROM artist ORDER BY name',
    gather {
        my $n = 0;    # this run's
        Ekorn::Pipeline->new(
            sub { ++$n . ". $_->[0]" },
            take(2),
        );
    },
);
say join ', ', $it->all;           # 1. Abba, 2. Blur
say join ', ', $it->reset->all;    # 1. Abba, 2. Blur
```

## 8. Sinks: saying what you want back

So far, `iterate` has always given an iterator, and you've asked it
for rows with `next`, `first`, `single` or `all`. A *sink* is another
way to say what you want back: a last stage that decides what the run
gives. Give one last, and `iterate` reads the run through and gives
you the sink's result, not an iterator.

The sinks are Ekorn::Pipeline's, from Ekorn::Pipeline::Sinks.
DBIx::Squirrel::Tooling's `:sinks` exports them all, as the set-up
does.

### Get every result, or how many

`keep_all` gives every result: a list, or, where one value is asked
for, an array reference. `count_items` gives how many there were:

```perl
my @names = $dbh->iterate(
    'SELECT name FROM artist ORDER BY id',
    pluck('name'),
    keep_all,
);
say "@names";    # Abba Blur Cream

my $names = $dbh->iterate(
    'SELECT name FROM artist ORDER BY id',
    pluck('name'),
    keep_all,
);
say ref $names;    # ARRAY

my $popular = $dbh->iterate('SELECT name FROM track WHERE plays > ?', 5000, count_items);
say $popular;    # 4
```

So `my $rows = ...` is the rows, never a count by accident: if you
want a count, say so with `count_items`. An empty result is an empty
array reference, which is true, so test it with `@$rows`.

### Get the first, the last, or the only one

`keep_first` gives the first result, and stops the run there.
`keep_last` reads every result, and gives the last. `keep_single`
gives the only one, warning at a second, as `single` does. Each gives
`undef` if there are none:

```perl
say $dbh->iterate(
    'SELECT name FROM track ORDER BY plays DESC',
    pluck('name'),
    keep_first,
);
# Dancing Queen

say $dbh->iterate(
    'SELECT name FROM track ORDER BY plays DESC',
    pluck('name'),
    keep_last,
);
# Country House

say $dbh->iterate(
    'SELECT name FROM artist WHERE id = ?', 3,
    pluck('name'),
    keep_single,
);
# Cream

my $nobody = $dbh->iterate('SELECT name FROM artist WHERE id = ?', 9, keep_single);
say defined $nobody ? 'found' : 'none';    # none
```

### Keep the first few

`keep(N)` keeps the first N results, and stops the run once it has
them, so no more rows are fetched:

```perl
my @top = $dbh->iterate(
    'SELECT name FROM track ORDER BY plays DESC',
    pluck('name'),
    keep(3),
);
say join ', ', @top;    # Dancing Queen, Sunshine of Your Love, Girls & Boys
```

### Write the results to a file

`to_file` writes each result to a file, a line each, and gives how
many it wrote. It closes the file however the run ends:

```perl
my $written = $dbh->iterate(
    'SELECT title FROM album ORDER BY year',
    pluck('title'),
    to_file('titles.txt'),
);
say $written;    # 4

open my $in, '<', 'titles.txt' or die "Can't read titles.txt: $!";
my @lines = <$in>;
close $in;
print @lines;
# Disraeli Gears
# Arrival
# Parklife
# The Great Escape
```

`to_fh` does the same to a filehandle you've opened, and leaves it
open. So an export of a large table is one call, a few rows in memory
at a time.

### Methods or sinks?

The iterator's methods and the sinks overlap, on purpose:

| You want | A method | A sink, given last |
|---|---|---|
| every result | `->all` | `keep_all` |
| the first | `->first` | `keep_first` |
| the only one | `->single` | `keep_single` |
| how many | | `count_items` |
| the first few | | `keep(N)` |
| the last | | `keep_last` |
| them in a file | | `to_file($path)` |

Use a method when you have an iterator in hand, or have already read
some of it: the methods take whatever's left. Use a sink when the call
should say, all at once, what it gives: it's the only way to have a
count, and it's what a function or named statement taking stages from
its caller can be given ([chapter
12](#12-a-function-for-each-database-and-statement), [chapter
14](#14-functions-that-take-stages-and-stages-for-others)). `all`
without stages is quicker, as it fetches every row in one go.

## 9. Rows as objects

Arrays are quick, and hashes are clear, but both fail quietly: a typo
in `$row->{titel}` gives `undef`, and the program carries on.
`results` gives rows as objects instead, with a method for each
column. A misspelt method dies, at the line with the typo.

### Have a method for each column

Ask for `results` where you'd ask for `iterate`. It takes the same
arguments, and gives the same kind of iterator, with every method of
chapters 4 to 8. The methods are named after the columns, in lower
case:

```perl
my $album = $dbh->results('SELECT id, Title, year FROM album WHERE id = $1', 2)->first;
say $album->title, ' (', $album->year, ')';    # Parklife (1994)

eval { $album->titel };
say $@ =~ m( \A Can't\ locate\ object\ method\ "titel" )x ? 'a typo, caught' : 'missed';    # a typo, caught
```

The rows are still arrays underneath, so `$album->[1]` works too.

### Reach a column that has no method

A column whose name can't be a method's, such as `COUNT(*)`, gets a
method if the statement gives it a name with `AS`. `get_column`
reaches any column, by its name or its position:

```perl
my $row = $dbh->results('SELECT COUNT(*), COUNT(*) AS albums FROM album')->first;
say $row->albums;                    # 4
say $row->get_column('COUNT(*)');    # 4
say $row->get_column(0);             # 4
```

### Give rows methods of your own

Make a subclass of DBIx::Squirrel::Result, and name it in the
`ekorn_result_class` attribute. Your methods sit beside the columns':

```perl
package My::Album {
    our @ISA = 'DBIx::Squirrel::Result';
    sub label ($self) { sprintf '%s (%d)', $self->title, $self->year }
}

my $albums = $dbh->results('SELECT title, year FROM album ORDER BY year', {ekorn_result_class => 'My::Album'});
while (my($album) = $albums->next) {
    say $album->label;
}
# Disraeli Gears (1967)
# Arrival (1976)
# Parklife (1994)
# The Great Escape (1995)
```

A column named as one of your methods gets no method of its own;
`get_column` still reaches it.

### Shape objects with stages, and end with a sink

Stages see the objects, and the sinks work as before. `pluck` takes a
column of an object too:

```perl
my @recent = $dbh->results(
    'SELECT title, year FROM album ORDER BY year',
    sub { $_->year >= 1990 ? $_ : () },
    pluck('title'),
    keep_all,
);
say "@recent";    # Parklife The Great Escape
```

## 10. Building pipelines from pipelines

The stages given to a call are a *pipeline*: a list of stages, run in
order. You can make one yourself, with `Ekorn::Pipeline->new`, and it
goes wherever a stage goes, standing for its stages. So a set of steps
you use often can be made once, named, and used everywhere.

### Make a pipeline once, and use it anywhere

```perl
use Ekorn::Pipeline;

my $hits = Ekorn::Pipeline->new(
    sub { $_->[1] >= 5000 ? $_ : () },    # 5,000 plays or more
    pluck('name'),
);

my $by_plays = 'SELECT name, plays FROM track ORDER BY plays DESC';
say join ', ', $dbh->iterate($by_plays, $hits)->all;             # Dancing Queen, Sunshine of Your Love, Girls & Boys, Parklife
say join ', ', $dbh->iterate(
    $by_plays,
    $hits,
    take(2),
)->all;
# Dancing Queen, Sunshine of Your Love

```

Its stages run in its place, as if written out there, with more stages
before or after it.

### Call a pipeline with values

A pipeline is also something you can call, like a sub, with any values
at all. It gives back what comes out of its last stage. That's how to
try a pipeline, or test it, without a database:

```perl
use Ekorn::Pipeline;

my $shout = Ekorn::Pipeline->new(
    sub { uc },
    sub { "$_!" },
);
say join ' ', $shout->('hello', 'world');    # HELLO! WORLD!
```

Stages that need a statement's column names, `as_hash`, and `pluck` by
a name for an array row, can't work there, as there's no statement:
they croak "Expected an iterator, for the column names". `pluck` by
name on hashes, which reads their keys, works anywhere.

### Name a pipeline, and use it by name

`Ekorn::Pipeline->named` names a pipeline, for the rest of the
program. `pipeline`, from Ekorn::Pipeline::Factories, makes a pipeline
from stages and names, and is the shortest way to say "this named
pipeline, then these":

```perl
use Ekorn::Pipeline;

Ekorn::Pipeline->named(shouted => sub { uc $_->[0] });

say join ', ', $dbh->iterate('SELECT name FROM artist ORDER BY id', pipeline('shouted'))->all;             # ABBA, BLUR, CREAM
say join ', ', $dbh->iterate('SELECT name FROM artist ORDER BY id', pipeline('shouted', take(1)))->all;    # ABBA
```

A name belongs to the package that named it, so two modules can each
have a `clean` of their own. A name is looked up when the pipeline is
made, so name it first. The Sugar's statements take names too
([chapter 12](#12-a-function-for-each-database-and-statement)).

### Run a handle through stages

`pipe` runs a database or statement handle itself through stages, and
gives back what comes out. `tap` does the same for the stages' side
effects, and gives back the handle, so a chain of calls can carry on:

```perl
my @names = $dbh->pipe(
    sub ($dbh) { @{ $dbh->selectcol_arrayref('SELECT name FROM artist ORDER BY id') } },
    sub { uc },
);
say "@names";    # ABBA BLUR CREAM

my $albums = $dbh->tap(sub ($dbh) { say 'albums: ', $dbh->selectrow_array('SELECT COUNT(*) FROM album') })
    ->selectrow_array('SELECT COUNT(*) FROM album WHERE year > 1990');
say "since 1990: $albums";
# albums: 4
# since 1990: 2
```

`tap` is handy for logging or checking something on the way through,
without breaking up a chain of method calls.

## 11. Chaining with | and @{}

Some queries read best as one line, left to right: the statement, then
what's done to its rows, then what comes back. With
Ekorn::Pipeline::Operators in force, an iterator takes `|`, and so
does what it makes:

```perl
use Ekorn::Pipeline::Operators;

my $top = $dbh->iterate('SELECT name FROM track ORDER BY plays DESC')
    | pluck('name')
    | take(3)
    | keep_all;
say join ', ', @$top;    # Dancing Queen, Sunshine of Your Love, Girls & Boys

my $n = $dbh->iterate('SELECT * FROM album') | count_items;
say $n;    # 4
```

The operators are in force only in the scope that says
`use Ekorn::Pipeline::Operators`. Elsewhere, `|` on an iterator
croaks, so a chain is never mistaken for Perl's own bitwise or.

### `|` always gives one value

This is the one thing to remember about `|`. Perl calls an operator
for exactly one value, so a chain ending in `keep_all` gives an array
reference, even assigned to an array:

```perl
use Ekorn::Pipeline::Operators;

my @oops = $dbh->iterate('SELECT name FROM artist')
    | pluck('name')
    | keep_all;
say scalar @oops;    # 1

my @names = @{
    $dbh->iterate('SELECT name FROM artist ORDER BY id')
        | pluck('name')
        | keep_all
};
say "@names";    # Abba Blur Cream

my @also = $dbh->iterate(
    'SELECT name FROM artist ORDER BY id',
    pluck('name'),
    keep_all,
);
say "@also";    # Abba Blur Cream
```

So for a list, put the chain in `@{ ... }`, or give the stages and the
sink to `iterate` as arguments, which gives a list where a list is
asked for.

### Read every result with `@{}`

`@{}` on an iterator, or on a chain without a sink, reads every
result:

```perl
use Ekorn::Pipeline::Operators;

my $it = $dbh->iterate('SELECT name FROM artist ORDER BY id', pluck('name'));
say "@$it";                     # Abba Blur Cream
say scalar @$it;                # 3
say "@{ $it | sub { lc } }";    # abba blur cream
```

It reads like an array, but it isn't one. Each use runs the query
again, from the first row: `scalar @$it` fetches every row to count
them, and `$it->[0]` fetches every row to give one. And `for (@$it)`
reads every row before the loop starts. So:

| You want | Write | Rather than |
|---|---|---|
| every result, as a reference | `$it \| keep_all` | |
| every result, as a list | `@{ $it \| keep_all }`, or `$sth->iterate(@values, keep_all)` | `my @rows = $it \| keep_all`, one element |
| the first | `$it \| keep_first`, fetching two rows | `$it->[0]`, fetching them all |
| how many | `$it \| count_items` | `scalar @$it`, keeping every row |
| the first few | `$it \| keep(5)` | `(@$it)[0 .. 4]`, fetching them all |
| each as it comes | `while (my($row) = $it->next) { ... }` | `for (@$it) { ... }`, fetching them all first |

A chain run only for what its sink does, such as writing a file, still
needs its result kept, as in `my $n = $it | to_file($path)`. Written
as a statement of its own, Perl warns about a useless `|` before the
chain ever runs.

## 12. A function for each database and statement

DBIx::Squirrel::Sugar gives each database you name, and each
statement, a function of its own. No handle to pass around, no global
variable to set up first: the database is connected to when it's first
used, and the statement is prepared once, and kept.

### Name a database

Defined with `use`, the function is there as the program compiles, so
it can be called without parentheses. Called with nothing, it's the
handle. Called with a statement and values, it runs it. With stages,
it gives an iterator, or a sink's result:

```perl
use DBIx::Squirrel::Sugar database => {
    music => ['dbi:SQLite:dbname=music.db', '', '', {RaiseError => 1}],
};

say ref music;    # DBIx::Squirrel::db

my $sth = music 'SELECT name FROM artist WHERE id = ?', 1;
say $sth->fetchrow_arrayref->[0];    # Abba

my @names = music 'SELECT name FROM artist ORDER BY id', sub { $_->[0] }, keep_all;
say "@names";    # Abba Blur Cream
```

### Name a statement, with stages of its own

A statement's definition is its database, its SQL, and any stages it
always has. Called, it takes values, then any stages for that call
only:

```perl
use DBIx::Squirrel::Sugar statement => {
    titles_by => [music => 'SELECT title FROM album WHERE artist_id = :artist ORDER BY year', sub { $_->[0] }],
    album     => [music => 'SELECT * FROM album WHERE id = ?'],
};

my @titles = titles_by artist => 2, keep_all;
say "@titles";    # Parklife The Great Escape

my @shouted = titles_by artist => 2, sub { uc }, keep_all;
say "@shouted";    # PARKLIFE THE GREAT ESCAPE

say titles_by(artist => 2, count_items);    # 2

my $it = titles_by artist => 1;
say ref $it;    # DBIx::Squirrel::Iterator

my $sth = album 1;
say $sth->fetchrow_hashref->{title};    # Arrival
```

Without stages, a statement gives its handle, executed. With stages,
its own or the call's, it gives an iterator, unless the last stage is
a sink, when it gives the sink's result.

### Define them as the program runs

`database` and `statement`, imported, define them while the program
runs, from configuration, say:

```perl
use DBIx::Squirrel::Sugar qw(database statement);

database(archive => 'dbi:SQLite:dbname=music.db', '', '', {RaiseError => 1});
statement(artist_count => archive => 'SELECT COUNT(*) FROM artist', sub { $_->[0] });

say artist_count(keep_single);    # 3
say ref database('archive');      # DBIx::Squirrel::db
```

`database('archive')`, given just the name, is the handle, from
anywhere in the program.

### Use a named pipeline in a definition

A statement's definition can name a pipeline. The name is looked up as
the statement is defined, so for a statement defined with `use`, name
the pipeline in a `BEGIN` block above it. When the statement is
called, a string is always a value, never a name:

```perl
use Ekorn::Pipeline;

BEGIN { Ekorn::Pipeline->named(loud => sub { uc $_->[0] }) }

use DBIx::Squirrel::Sugar statement => {
    loud_titles => [music => 'SELECT title FROM album WHERE year < ? ORDER BY year', 'loud'],
};

say join ', ', loud_titles(1990, keep_all);    # DISRAELI GEARS, ARRIVAL
```

### Mind the names you import

A statement's function goes in your package, so its name can't be one
your package has already, such as a sink you've imported. Defining it
croaks: "Expected no function of the name in main already
(count_items)". With Tooling's `:all`, that's any name in its
[table](#import-everything-from-one-place): name statements for what
they read, as `titles_by`, or import fewer tags.

## 13. Caching and connections

### Prepare a statement once, wherever it's used

`prepare_cached` keeps the statement handle on the database handle, as
the DBI does, so the same SQL is prepared once. If an iterator is part
way through the cached handle, it's left alone, and a new handle takes
its place:

```perl
my $sql   = 'SELECT name FROM artist ORDER BY id';
my $first = $dbh->prepare_cached($sql)->iterate(sub { $_->[0] });
my($name) = $first->next;
say $name;    # Abba

my $second = $dbh->prepare_cached($sql)->iterate(sub { $_->[0] });
say join ' ', $second->all;    # Abba Blur Cream
say join ' ', $first->all;     # Blur Cream
```

### Share a connection

`connect_cached` gives back the same handle for the same arguments:

```perl
my $one = DBIx::Squirrel->connect_cached('dbi:SQLite:dbname=music.db', '', '', {RaiseError => 1});
my $two = DBIx::Squirrel->connect_cached('dbi:SQLite:dbname=music.db', '', '', {RaiseError => 1});
say $one == $two ? 'the same handle' : 'two handles';    # the same handle
```

### Let the Sugar connect again

A Sugar database connects with `connect_cached` when it's first used.
Its handle is kept, without asking the database whether it's there on
every call. If it's been disconnected, or its last call failed and the
connection has gone, the next call makes a new one:

```perl
use DBIx::Squirrel::Sugar database => {
    chart => ['dbi:SQLite:dbname=music.db', '', '', {RaiseError => 1, PrintError => 0}],
};

my $first = chart;
$first->disconnect;
my $again = chart;
say $again == $first ? 'the same handle' : 'a new handle';    # a new handle
say $again->ping ? 'connected' : 'not connected';            # connected
```

The call just after a connection drops fails, as it would with plain
DBI. The one after that has a new connection.

## 14. Functions that take stages, and stages for others

This is where stages pay off most. A function that runs a query can
take stages from its caller, and hand them on. It no longer needs an
option for "only the first ten", "just the names" or "how many": its
caller writes those as stages, beside the call, and the function stays
the size of what only it knows, the SQL.

### Let callers of your functions add stages

Pass the caller's stages to `iterate`, after your values. Your caller
then chooses an iterator, a list, a count or a file, with the stages
and sink they give:

```perl
# The tracks of an artist, through whatever stages the caller gives.
sub tracks_by ($artist, @stages) {
    return $dbh->iterate(
        [   'SELECT track.name, track.plays FROM track',
            'JOIN album ON album.id = track.album_id',
            'JOIN artist ON artist.id = album.artist_id',
            'WHERE artist.name = ? ORDER BY track.plays DESC',
        ],
        $artist, @stages,
    );
}

say ref tracks_by('Blur');                                       # DBIx::Squirrel::Iterator
say join ', ', tracks_by(
    'Blur',
    pluck('name'),
    keep_all,
);
# Girls & Boys, Parklife, Country House

say join ', ', tracks_by(
    'Blur',
    pluck('name'),
    take(1),
    keep_all,
);
# Girls & Boys

say tracks_by('Abba', count_items);                              # 2
```

Compared with options, a stage can do anything the caller needs, not
only what you thought of, and the caller already knows how stages
work.

### Take stages for values that don't come from a database

The same idea works for any function, with values from anywhere: make
a pipeline of the caller's stages, and call it with your values:

```perl
use Ekorn::Pipeline;

# The bands, as hashes, through whatever stages the caller gives
sub bands (@stages) {
    my @bands = (
        {name => 'Abba',  formed => 1972},
        {name => 'Blur',  formed => 1988},
        {name => 'Cream', formed => 1966},
    );
    return Ekorn::Pipeline->new(@stages)->(@bands);
}

my @older = bands(
    sub { $_->{formed} < 1980 ? $_ : () },
    pluck('name'),
);
say "@older";    # Abba Cream
```

`pluck` by name works here, as these rows are hashes and have their
own keys. Loading the pipeline and the stages doesn't load the DBI.

### Decide where a stage belongs

A stage goes where what it needs to know is. Ask what it has to know
to do its job, not what its values happen to be:

- **A stage that needs a database, a statement or a row's column
  names** goes with DBIx::Squirrel, under `DBIx::Squirrel::Stages::`,
  as `pluck` and `as_hash` do.
- **A stage that would work on values from anywhere** belongs with
  Ekorn::Pipeline, under `Ekorn::Pipeline::Stages::`, where any
  function's stages can use it, even if you wrote it for rows. A stage
  that works on hashes from a query works as well on hashes from a
  JSON file.

Ekorn::Pipeline can't depend on DBIx::Squirrel, so a stage that would
`use` any of DBIx::Squirrel belongs with DBIx::Squirrel.

### Write a function that makes a stage

A stage for others is made by a function, as `take(10)` is, so the
function can check its options once, when it's called, rather than on
every row. `croakf`, from DBIx::Squirrel::Errors, reports a mistake at
your caller's line, when the module lists
`@DBIx::Squirrel::Errors::INTERNAL` as its `@CARP_NOT`. Keep any state
in a `gather` block, so it starts afresh on each run:

```perl
package My::Stages {
    use DBIx::Squirrel::Errors qw(croakf);
    use DBIx::Squirrel::Gather;

    our @CARP_NOT = @DBIx::Squirrel::Errors::INTERNAL;

    # Each value, numbered from $start on each run
    sub numbered_from ($start) {
        croakf 'Expected a whole number to start from (%s)', $start
            unless $start =~ m( \A \d+ \z )x;
        return gather {
            my $n = $start;
            return sub ($value) { $n++ . ". $value" };
        };
    }
}

my $chart = $dbh->iterate('SELECT name FROM artist ORDER BY id', sub { $_->[0] }, My::Stages::numbered_from(1));
say join ', ', $chart->all;           # 1. Abba, 2. Blur, 3. Cream
say join ', ', $chart->reset->all;    # 1. Abba, 2. Blur, 3. Cream

eval { My::Stages::numbered_from('one') };
print $@;    # Expected a whole number to start from (one) at ... line ...
```

### Make a stage out of others

A function can return a pipeline, made of other stages. It goes
wherever a stage goes, and works on each shape of row the stages in it
do:

```perl
use Ekorn::Pipeline;

sub loud_names () {
    return Ekorn::Pipeline->new(
        pluck('name'),
        sub { uc },
    );
}

say join ' ', $dbh->iterate('SELECT id, name FROM artist ORDER BY id', loud_names)->all;    # ABBA BLUR CREAM
say join ' ', $dbh->results('SELECT id, name FROM artist ORDER BY id', loud_names)->all;    # ABBA BLUR CREAM
```

### Test a stage

A pipeline called with values tests a stage without a database. Call
it twice, to show it starts afresh:

<!-- not run -->
```perl
use Test2::V0;
use Ekorn::Pipeline;
use My::Stages;

my $p = Ekorn::Pipeline->new(My::Stages::numbered_from(1));
is [$p->(qw(a b))], ['1. a', '2. b'], 'numbered';
is [$p->(qw(c))],   ['1. c'],         'from 1 on each run';

done_testing;
```

Then run it over rows from an in-memory SQLite database, in each shape
it takes: arrays, hashes from `ekorn_slice`, and objects from
`results`.

### Publish a module of stages

Name it for its job, in the namespace where its stages belong, and
name the distribution after it, as `DBIx-Squirrel-Stages-JSON` for
`DBIx::Squirrel::Stages::JSON`. Have it require the DBIx::Squirrel it
was tested with. The reference's [Stages for
others](REFERENCE.md#stages-for-others) has the details, and
Ekorn::Pipeline's guide has more, in [Building parts for
others](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/HOWTO.md#10-building-parts-for-others),
including how to write sources and sinks of your own.

## 15. When things go wrong

### Find the line that went wrong

Every error is reported at the line of your code that called
DBIx::Squirrel, including the DBI's own errors, rather than somewhere
inside a module:

```perl
eval { $dbh->prepare('SELEC name FROM artist') };
print $@;    # DBD::SQLite::db prepare failed: near "SELEC": syntax error at ... line ...
```

So are the warnings the DBI gives under `PrintError`, its default.
Each names the method you called, as plain DBI does:

```perl
my $chatty = DBIx::Squirrel->connect('dbi:SQLite:dbname=music.db', {RaiseError => 0, PrintError => 1});
my $warned = '';
local $SIG{__WARN__} = sub ($warning) { $warned = $warning };
$chatty->selectrow_array('SELECT * FROM nowhere');
print $warned;    # DBD::SQLite::db selectrow_array failed: no such table: nowhere at ... line ...
```

### Rely on `connect` and `prepare` croaking

`connect` and `prepare` croak whatever `RaiseError` says, so they need
no `or die`. Without `RaiseError`, the other methods return what the
DBI's methods return:

```perl
my $quiet = DBIx::Squirrel->connect('dbi:SQLite:dbname=music.db', {RaiseError => 0, PrintError => 0});

my $row = $quiet->selectrow_arrayref('SELEC 1');
say defined $row ? 'a row' : 'undef, as from the DBI';    # undef, as from the DBI

eval { $quiet->prepare('SELEC 1') };
say $@ ? 'prepare croaked' : 'prepare returned';    # prepare croaked
```

### See which stage went wrong

A stage that dies is reported at the line that asked for the result,
with the stage's place in the list, and its message below:

```perl
my $it = $dbh->iterate(
    'SELECT name FROM artist',
    sub { $_ },
    sub { die "no names today\n" },
);
eval { $it->next };
print $@;
# Pipeline stage #2 failed at ... line ...:
#     no names today

say $it->ended;    # died
```

A stage inside a pipeline given as a stage is named by its place in
each: `#2.2` is the second stage of the pipeline given as stage #2. A
stage of a named pipeline gives the name too, as in
`#2.2 (main::fussy#2)`.

Once a stage dies, the run has ended. `next` gives nothing more, and
the statement is finished; `reset` runs it again from the start. To
pass over a row a stage can't handle, catch the error in the stage, as
in [chapter 6](#catch-errors-in-a-stage-but-let-a-stop-through).

### Handle errors your own way

The DBI's `HandleError` works as it does with plain DBI. An error it
throws, such as an exception object, is passed on unchanged:

```perl
package My::Error {
    sub new ($class, $message) { return bless {message => $message}, $class }
}

my $strict = DBIx::Squirrel->connect('dbi:SQLite:dbname=music.db', {
    PrintError  => 0,
    HandleError => sub ($message, $handle, $value) { die My::Error->new($message) },
});
eval { $strict->do('DELETE FROM nowhere') };
say ref $@;           # My::Error
say $@->{message};    # DBD::SQLite::db do failed: no such table: nowhere
```

## 16. Questions you may have

### Do I have to give up the DBI?

No. Every handle is a DBI handle, every DBI method works, and any
driver the DBI supports works. Where DBIx::Squirrel and plain DBI do
the same thing, they give the same result. You can add it to a program
one query at a time, and take a handle you already have ([chapter
1](#1-still-the-dbi)). The tests run on SQLite, MySQL and PostgreSQL.

### Do I need to learn Ekorn::Pipeline?

Not to use DBIx::Squirrel: this guide shows its parts as they apply to
rows, and you write stages as plain subs. Ekorn::Pipeline is worth a
look when you want stages for values that don't come from a database,
or to write sources and sinks of your own. Its [user
guide](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/HOWTO.md)
starts from the beginning.

### How fast is it?

Close to the DBI where it does the DBI's work, and a little slower per
row where it does more. Timed on a real table of 297,848 narrow rows,
in SQLite, the best of three runs, in seconds:

| How the rows are read | Seconds |
|---|---|
| the DBI's `fetchrow_arrayref`, in a loop | 0.079 |
| the DBI's `selectall_arrayref` | 0.107 |
| DBIx::Squirrel's `selectall_arrayref` | 0.107 |
| `iterate(...)->all` | 0.156 |
| `map` over `iterate(...)->all` | 0.169 |
| `next`, in a loop | 0.276 |
| `iterate(..., keep_all)` | 0.533 |
| `iterate(..., $stage)->all` | 0.637 |

On wide rows, 21,826 of them averaging 24 KB, fetching the data costs
far more than anything around it, and every one of those ways takes
between 0.13 and 0.23 seconds.

So: the select methods cost nothing over the DBI's. `all` with no
stages takes about one and a half times as long as
`selectall_arrayref`. A stage costs under two microseconds a row; over
a hundred thousand rows, that's a sixth of a second, and on most
queries it's lost in the time the database takes. When every row of a
big result is wanted, and only needs changing, `map` over `all` is
quickest. Use stages when you might not need every row, when the
result is too big to hold, or when the steps should travel with the
query.

### Will a large result fill my memory?

Not through an iterator. Rows are fetched a few at a time, up to 64,
and each goes through the stages and on its way before the next batch
is fetched. Only `all`, `keep_all` and the like hold every result,
because that's what you asked for. To process a large table, read it
with `next`, or with a sink such as `count_items` or `to_file`, which
holds nothing.

### Does it write SQL for me?

No, on purpose. You write the SQL, and DBIx::Squirrel runs it. If you
want SQL built from Perl data structures, SQL::Abstract does that, and
its output can be given to `iterate` like any other statement, with
its `?` placeholders and values.

### How does it compare with DBIx::Class?

DBIx::Class is an ORM: you describe your schema as Perl classes, with
their relationships, and it writes the SQL and gives you objects. It's
the right tool when your program is organised around those objects,
and you'd rather not write SQL. DBIx::Squirrel is the opposite choice:
SQL first, no schema to describe, and rows as plain arrays or hashes,
or light objects when you ask for them ([chapter
9](#9-rows-as-objects)). There's nothing to set up before your first
query.

### How does it compare with DBIx::Simple?

Both make the DBI pleasanter to use, and both fill a list of values
into the SQL: DBIx::Simple with its `(??)`, DBIx::Squirrel with `...`
in front of a placeholder. DBIx::Simple wraps a DBI handle in an
object of its own, with methods for getting results in various shapes.
DBIx::Squirrel extends the DBI's own handles instead, so existing DBI
code and modules take them as they are, and it adds placeholders in
any style, and the pipeline, which DBIx::Simple doesn't have.

### Why does `my @rows = $it | keep_all` give one element?

Because Perl calls an operator for one value. The chain gives an array
reference, and the array gets that one reference. Use
`@{ $it | keep_all }`, or give the stages and sink to `iterate` as
arguments. [Chapter 11](#11-chaining-with--and-) has the details.

### What doesn't it do?

It doesn't generate SQL, describe schemas, manage migrations or run
queries in parallel. Transactions are the DBI's. A statement handle
runs one statement at a time, so two iterators can't read the same
handle at once ([chapter
4](#use-one-iterator-at-a-time-on-a-statement-handle)). And stages run
in Perl, so work the database can do, such as filtering and limiting,
is better done in SQL.

## 17. Coming from version 1 or 2

The reference's [Upgrading from 2.x](REFERENCE.md#upgrading-from-2x)
and [Upgrading from 1.x](REFERENCE.md#upgrading-from-1x) list every
change. These are the changes most code meets first.

### From version 2

- **A call taking stages gives an iterator,** unless its last stage is
  a sink. That includes the Sugar's statements, which used to give
  every result, or a count. Add `keep_all` for the results, or
  `count_items` for a count.
- **`all` asked for one value gives an array reference,** not a count.
  Use `count_items` for a count.
- **`count` is gone.** Use `count_items` given last, or `count_into`
  as a stage, to count as you go.
- **`single` warns at a second result,** and gives the first, where it
  used to croak.
- **DBIx::Squirrel::Pipeline is gone.** Make pipelines with
  `Ekorn::Pipeline->new`. DBIx::Squirrel::Stop still exports `Stop`,
  but to throw a stop as a method, use `Ekorn::Pipeline::Stop->throw`.
- **A `gather` block's second part is its flush,** what version 2
  called the end function. It works as before. An end, told how the
  run ended, can follow it.

```perl
use DBIx::Squirrel::Sugar statement => {
    every_artist => [music => 'SELECT name FROM artist ORDER BY id', sub { $_->[0] }],
};

my @names = every_artist(keep_all);         # version 2: every_artist()
say "@names";                               # Abba Blur Cream
say every_artist(count_items);              # 3
```

### From version 1

Version 2 was a rewrite for Perl 5.36 or later. In particular:

- **Database entities are now the Sugar.** Version 1 gave helpers a
  handle at run time; the Sugar defines a database by how to connect,
  and a statement by its SQL and stages ([chapter
  12](#12-a-function-for-each-database-and-statement)).
- **Stages come after the bind values,** not with them in an array
  reference.
- **A column's method is in lower case.** `get_column` takes a name in
  any case.

<!-- not run -->
```perl
# Version 1
use DBIx::Squirrel database_entities => [qw(db artist)];
db(DBIx::Squirrel->connect($dsn, $user, $pass));
artist(db->results('SELECT * FROM artist WHERE name = ? LIMIT 1'));
say artist('Blur')->single->Id;
```

```perl
use DBIx::Squirrel::Sugar statement => {
    artist_id => [music => 'SELECT id FROM artist WHERE name = ? LIMIT 1', sub { $_->[0] }],
};

say artist_id('Blur', keep_single);    # 2
```
