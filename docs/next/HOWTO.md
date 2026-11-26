# DBIx::Squirrel user guide

<!-- stopwords: bitwise flatMap jsonb's gazetteer ORM ORMs -->

You write the SQL; DBIx::Squirrel takes away the DBI machinery around
it, with placeholders in any common style, a list into `IN (...)` from
one placeholder, and results read through an iterator, and every
handle is still a DBI handle. Rows can also be changed as they're
read, by small functions written beside the query.

This guide comes in two parts. Part 1 is DBIx::Squirrel: the round
trip to the database, a query sent and its rows read back. It asks you
to learn three things: placeholders, the iterator, and stages, the
small functions that change rows. Each is useful without the next, so
you can stop at any of them, and if you stop at the end of Part 1, you
have the whole library.

Part 2 is a different job: data crossing the database's edge. Query
results written to files, JSON and CSV, loaded from them in batches,
or sent to several places in one run. It's done with a distribution of
its own, which Part 2 introduces, and it's there for those who want
it.

Part 1 starts at the bottom, with the DBI underneath, and works
upwards a layer at a time: statements, rows read one at a time,
stages, and the shortcuts that sit on top. Each layer uses only what
the layers before it have shown, so you can read it from the start,
or go straight to the layer you need. Every example runs as it stands,
and its comments say what it prints.

[The reference](REFERENCE.md) describes every method and attribute in
full. This guide is the tour; the reference is the map.

## Contents

- [The layers, at a glance](#the-layers-at-a-glance)
- [The examples' database](#the-examples-database)
- **[Part 1: DBIx::Squirrel](#part-1-dbixsquirrel)**
- [1. Still the DBI](#1-still-the-dbi)
- [2. Writing statements](#2-writing-statements)
- [3. Binding values and running statements](#3-binding-values-and-running-statements)
- [4. A statement as a source of rows](#4-a-statement-as-a-source-of-rows)
- [5. Stages: shaping rows on the way out](#5-stages-shaping-rows-on-the-way-out)
- [6. Stopping early](#6-stopping-early)
- [7. Parts made for each run](#7-parts-made-for-each-run)
- [8. Rows as objects](#8-rows-as-objects)
- [9. A function for each database and statement](#9-a-function-for-each-database-and-statement)
- [10. Caching and connections](#10-caching-and-connections)
- [11. Functions that take stages, and stages for others](#11-functions-that-take-stages-and-stages-for-others)
- [12. When things go wrong](#12-when-things-go-wrong)
- [13. Questions you may have](#13-questions-you-may-have)
- [Where you can stop](#where-you-can-stop)
- **[Part 2: With Ekorn::Pipeline](#part-2-with-ekornpipeline)**
- [14. Import everything from one place](#14-import-everything-from-one-place)
- [15. Sinks: saying what you want back](#15-sinks-saying-what-you-want-back)
- [16. Files, JSON and CSV](#16-files-json-and-csv)
- [17. Building pipelines from pipelines](#17-building-pipelines-from-pipelines)
- [18. Loading rows as they arrive](#18-loading-rows-as-they-arrive)
- [19. Several places in one run](#19-several-places-in-one-run)
- [20. Chaining with | and @{}](#20-chaining-with--and-)
- [21. Stages beyond the database](#21-stages-beyond-the-database)
- [22. Coming from version 1 or 2](#22-coming-from-version-1-or-2)

## The layers, at a glance

Reading a query with DBIx::Squirrel has the same shape every time.
Rows come from a statement, go through stages one at a time, and come
out of an iterator, as you ask for them:

```text
   statement  -->  stage  -->  stage  -->  iterator
  (the rows        (change, drop, multiply,      (what you
  it fetches)       or stop: a row at a time)     read)
```

Part 1 is built in layers around that shape, and follows them from
the bottom up:

| Layer | What it gives you | Chapter |
|---|---|---|
| The DBI | handles that are DBI handles, so nothing you know stops working | 1 |
| Statements | placeholders in any style, lists of values, SQL left as you wrote it | 2 |
| Binding and running | values checked before they reach the database; the DBI's methods, tidied | 3 |
| Iterators | a statement as a source: rows read only as they're wanted, and the handle finished for you | 4 |
| Stages | small steps beside the query, shaping each row on its way out | 5 |
| Stopping | any stage can say "enough", and no more rows are fetched | 6 |
| Parts made for each run | stages that keep a count or a batch, fresh for each run | 7 |
| Row objects | rows with a method for each column, and methods of your own | 8 |
| Sugar | a function for each database and each statement | 9 |

Above them sit caching and connections (chapter 10), and your own
functions and stages (chapter 11). Chapter 12 covers errors, and
chapter 13 answers the questions people ask first, including how fast
it is.

## The examples' database

Every example runs against this small SQLite database, a file called
`music.db`, made here. The examples follow on from each other, so
`$dbh` is this handle wherever it appears. Nothing in the guide
changes the data for good: an example that writes rolls its change
back, so what each example prints is what you'll see. Each example
after it imports what it uses, from the module that makes it, so it
works when copied, with a handle of your own as `$dbh`:

```perl
use v5.36;
use DBIx::Squirrel;

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

## Part 1: DBIx::Squirrel

Everything in this part is DBIx::Squirrel's own: the DBI's handles,
extended, with placeholders, the iterator and stages. It's the whole
library, and nothing in it needs Part 2.

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

With the DBI, the statement is built for each list, with a `?` for
each value:

```perl
my @years = (1967, 1994);
my $marks = join ', ', ('?') x @years;
my $built = $dbh->selectcol_arrayref(
    "SELECT title FROM album WHERE year IN ($marks) ORDER BY year",
    undef, @years,
);
say "@$built";    # Disraeli Gears Parklife
```

With DBIx::Squirrel, put `...` in front of a placeholder, and give it
an array reference. It's written as a `?` for each value, and the SQL
stays one string, the same whatever the list:

```perl
my $titles = $dbh->selectcol_arrayref(
    'SELECT title FROM album WHERE year IN (...:years) ORDER BY year',
    years => [1967, 1994],
);
say "@$titles";    # Disraeli Gears Parklife

my $names = $dbh->selectcol_arrayref('SELECT name FROM artist WHERE id IN (...?)', [1, 3]);
say "@$names";     # Abba Cream
```

The statement is prepared for the number of values, so give
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

With `?`, the DBI counts the values, but can't tell their order, so
two swapped run without a word. Bound by name, with the DBI's own
`bind_param`, a placeholder left without a value is `NULL`, and the
query quietly finds nothing:

```perl
use DBI;

my $plain = DBI->connect('dbi:SQLite:dbname=music.db', '', '', {RaiseError => 1});
my $sth   = $plain->prepare('SELECT name FROM artist WHERE id = :id AND name = :name');
$sth->bind_param(':id', 1);
$sth->execute;
say $sth->fetchrow_arrayref ? 'a row' : 'nothing, and no error';    # nothing, and no error
```

Give a DBIx::Squirrel statement the wrong values, and it croaks at
your line, saying which placeholder went without. Named values go in
any order, so none can be swapped:

```perl
my $sth = $dbh->prepare('SELECT name FROM artist WHERE id = :id AND name = :name');
eval { $sth->execute(id => 1) };
print $@;    # Expected a value for each placeholder (none for name) at ... line ...
```

### Change rows with `do`

`do` takes the bind values straight after the statement, without the
`undef` the DBI wants for the attributes in between. It returns the
number of rows changed, as the DBI's does, and `0E0`, which is true
but zero, when there were none, so `or die` still catches only a
failure:

```perl
$dbh->begin_work;
my $rows = $dbh->do('UPDATE track SET plays = plays + 1 WHERE album_id = :album', album => 1);
say $rows;    # 2

my $none = $dbh->do('UPDATE track SET plays = 0 WHERE album_id = :album', album => 99);
say $none;                                           # 0E0
say $none == 0 ? 'no rows changed' : 'some rows';    # no rows changed
$dbh->rollback;
```

The attributes can still be given, as a hash reference, or `undef`,
straight after the statement. Only an unblessed hash reference or
`undef` there is taken for them, and an object is a bind value, as it
is to the DBI, so named values given in a hash reference need the
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
my @slugs = $dbh->selectall_array(
    'SELECT title FROM album ORDER BY year',
    sub ($row) { $row->[0] },      # each row, into its title
    sub { lc s( \W+ )(-)xgr },     # each title, as a slug for a URL
);
say "@slugs";    # disraeli-gears arrival parklife the-great-escape
```

The others give one value, a reference, so their first stage gets
that: `selectall_arrayref`'s array of rows, say, which a stage can
turn into names all at once:

```perl
my @names = $dbh->selectall_arrayref('SELECT name FROM artist ORDER BY name', sub ($rows) { map { $_->[0] } @$rows });
say "@names";    # Abba Blur Cream
```

`selectrow_array` gives the row's values, one at a time. Asked for one
value, a call with stages gives how many came out. Without stages,
each method gives exactly what the DBI's does.

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
twice as many each time a batch is used up, up to 64, where a bigger
batch reads hardly any faster. So a short read fetches very little,
and a long one doesn't call the driver for every row, or hold more
than 64 rows of its own.

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
asked for, as an array reference. It's never a count: for a count of
rows, ask the database, with `SELECT COUNT(*)`, and to count as rows
go by, see `count_into` in [chapter
5](#watch-rows-go-by-or-count-them).

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
| memory | `selectall_*` holds every row | a few rows at a time, up to 64, though the driver may hold more |

The iterator's real strength shows in the next chapter: whatever you'd
do to each row in the loop can go beside the query instead, as stages.

## 5. Stages: shaping rows on the way out

A *stage* is a sub that's given one row, and returns what should go
on: the row changed, nothing at all, or several values in its place.
Give `iterate` stages after its values, and each row goes through them
in order. What comes out of the last stage is what you read.

That's all a stage is. It's an ordinary sub, so anything Perl can do,
a stage can do, and it's tested like any sub. DBIx::Squirrel feeds
them rows, and has ready-made stages of its own, in four modules:
DBIx::Squirrel::Stages::Rows, ::Flow, ::Batch and ::Taps. Each
exports its commonest stages by default, and the rest on request. The
examples ask for each by name, so you can see where it comes from.

### Change each row

Return one value, and it takes the row's place. A stage gets its value
as its argument, and in `$_`, so write whichever reads best:

```perl
use DBIx::Squirrel::Stages::Rows qw(pluck);

my @titles = $dbh->iterate('SELECT title, year FROM album ORDER BY year', sub ($row) { "$row->[0] ($row->[1])" })->all;
say for @titles;
# Disraeli Gears (1967)
# Arrival (1976)
# Parklife (1994)
# The Great Escape (1995)

my @names = $dbh->iterate('SELECT name FROM artist ORDER BY id', pluck)->all;
say "@names";    # Abba Blur Cream
```

### Leave rows out

Return an empty list, and the row is dropped:

Say the tracks already on your phone are in a hash, read from its
playlist. The database has never heard of your phone, so no `WHERE`
can ask it which tracks are still to copy. A stage can:

```perl
my %on_my_phone = map { $_ => 1 } 'Dancing Queen', 'Parklife', 'Sunshine of Your Love';

my @to_copy = $dbh->iterate(
    'SELECT name FROM track ORDER BY id',
    sub { $on_my_phone{ $_->[0] } ? () : $_ },    # leave out what's there
    sub { $_->[0] },                               # then just the name
)->all;
say join ', ', @to_copy;    # Knowing Me, Knowing You, Girls & Boys, Country House
```

That's a filter in Perl, and `drop_if`, from
DBIx::Squirrel::Stages::Flow on request, says the same in a word:
`drop_if { $on_my_phone{ $_->[0] } }` drops each row its block is true
of, and `take_if` keeps each ([chapter
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
use DBIx::Squirrel::Stages::Rows qw(pluck as_hash);

my @titles = $dbh->iterate('SELECT title, year FROM album ORDER BY year', pluck('title'))->all;
say "@titles";    # Disraeli Gears Arrival Parklife The Great Escape

my $album = $dbh->iterate('SELECT title, year FROM album WHERE id = 2', as_hash)->first;
say "$album->{title} ($album->{year})";    # Parklife (1994)
```

They work whatever shape the rows come in: arrays, hashes, or the row
objects of [chapter 8](#8-rows-as-objects). To find a name's place in
an array, they ask the statement for its column names, as the rows go
by.

That has a catch. The column names are the statement's, not the row's.
After a stage that reshapes the rows, `pluck` by name still looks in
the statement's place for the column, and finds whatever's there now,
without a word. Make the rows hashes first, and `pluck` by name reads
each hash's own keys, however a stage has changed them:

```perl
use DBIx::Squirrel::Stages::Rows qw(pluck as_hash);

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
use DBIx::Squirrel::Stages::Rows qw(pluck);
use DBIx::Squirrel::Context qw(result_number result_original);

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
up a number. Each run counts its own, from 1 again after a `reset`.

### Watch rows go by, or count them

`peek` and `count_into`, from DBIx::Squirrel::Stages::Taps, look at
each value as it passes, and pass it on unchanged. They're how you see
what the stages are doing:

```perl
use DBIx::Squirrel::Stages::Rows qw(pluck);
use DBIx::Squirrel::Stages::Taps qw(count_into peek);

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
debug, and to be taken out before the code goes live. With
Text::Redact::Secrets installed, it redacts the secrets it finds, as
the reference's [Canned stages](REFERENCE.md#canned-stages) says.

### Compared with `map` over every row

The obvious alternative is to fetch every row and use Perl's own `map`
and `grep`:

```perl
my @hits = map { $_->[0] } grep { $_->[1] >= 6000 }
    @{ $dbh->selectall_arrayref('SELECT name, plays FROM track ORDER BY id') };
say join ', ', @hits;    # Dancing Queen, Girls & Boys, Sunshine of Your Love
```

For a small result that's read in full, that's fine, and it's quicker:
[chapter 13](#13-questions-you-may-have) has the numbers. Stages earn
their keep when:

- **you may not need every row,** as a stage can stop the reading
  early ([chapter 6](#6-stopping-early)), so the rest are never
  fetched;
- **the result is large,** as rows go through a few at a time, never
  all held at once;
- **the steps should travel with the query,** given to a function, or
  kept with a named statement ([chapter
  9](#9-a-function-for-each-database-and-statement));
- **the steps are worth reusing,** as a function that makes a stage
  can be called wherever stages go ([chapter
  11](#write-a-function-that-makes-a-stage)).

## 6. Stopping early

A stage can say "that's enough". The run stops there: the rows already
through are kept, nothing else is processed, and no more rows are
fetched from the database.

### Stop from a stage

`Stop`, from DBIx::Squirrel::Stop, ends the run. Values given to it go
on through the stages after it, as the last ones:

```perl
use DBIx::Squirrel::Stop qw(Stop);

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
use DBIx::Squirrel::Stages::Rows qw(pluck);
use DBIx::Squirrel::Stages::Flow qw(drop_if drop take);

my %on_my_phone = map { $_ => 1 } 'Dancing Queen', 'Parklife', 'Sunshine of Your Love';

my @page = $dbh->iterate(
    'SELECT name FROM track ORDER BY id',
    pluck,
    drop_if { $on_my_phone{$_} },    # the tracks still to copy
    drop(1),                         # the second and third of them
    take(2),
)->all;
say for @page;
# Girls & Boys
# Country House
```

The page is of what's left after a test in Perl, which SQL's `LIMIT`
and `OFFSET` can't see. With nothing in Perl before them, put `LIMIT`
and `OFFSET` in the SQL instead, and the database sends only the
page.

With the DBI, the same page is a loop, with a test, a count to skip,
a count to keep, and a `finish` for the rows left unread:

```perl
my %on_my_phone = map { $_ => 1 } 'Dancing Queen', 'Parklife', 'Sunshine of Your Love';

my $sth = $dbh->prepare('SELECT name FROM track ORDER BY id');
$sth->execute;
my($skipped, @page);
while (my($name) = $sth->fetchrow_array) {
    next if $on_my_phone{$name};
    next if $skipped++ < 1;
    push @page, $name;
    last if @page == 2;
}
$sth->finish;
say for @page;
# Girls & Boys
# Country House
```

The stages say each step once, in the order it happens, and stop the
reading as the loop's `last` does.

### Keep or drop rows by a test

`take_if` passes on each value its block is true of, and `drop_if`
each it's false of. They test every value, as Perl's `grep` does, and
never stop the run, unlike `take_while`, which stops at the first
value its test fails:

```perl
use DBIx::Squirrel::Stages::Flow qw(take_if drop_if take_while);

my %on_my_phone = map { $_ => 1 } 'Dancing Queen', 'Parklife', 'Sunshine of Your Love';

my @copied = $dbh->iterate(
    'SELECT name FROM track ORDER BY id',
    take_if { $on_my_phone{ $_->[0] } },
    sub { $_->[0] },
)->all;
say join ', ', @copied;    # Dancing Queen, Parklife, Sunshine of Your Love

my @to_copy = $dbh->iterate(
    'SELECT name FROM track ORDER BY id',
    drop_if { $on_my_phone{ $_->[0] } },
    sub { $_->[0] },
)->all;
say join ', ', @to_copy;    # Knowing Me, Knowing You, Girls & Boys, Country House

my @until = $dbh->iterate(
    'SELECT name FROM track ORDER BY id',
    take_while { $on_my_phone{ $_->[0] } },
    sub { $_->[0] },
)->all;
say join ', ', @until;    # Dancing Queen
```

The last stops at Knowing Me, Knowing You, the first track that fails
its test, so the tracks after it are never fetched.

A test the database could do belongs in the `WHERE`. The one time it
earns a place in a stage is while you're debugging: to try a condition
on a query's rows without touching the query, say one shared with
other code, and move it into the SQL once it's right:

```perl
use DBIx::Squirrel::Stages::Flow qw(take_if);

my $shared = 'SELECT name, plays FROM track ORDER BY id';    # not yours to change

my @would_keep = $dbh->iterate(
    $shared,
    take_if { $_->[1] > 6000 },    # trying it out, before it goes in a WHERE
    sub { $_->[0] },
)->all;
say join ', ', @would_keep;    # Dancing Queen, Girls & Boys, Sunshine of Your Love
```

### Take while a test holds, or skip until it fails

`take_while` passes values on while its block is true of them, and
stops at the first it isn't. `drop_while` passes over values while its
block is true, then passes on the rest:

Both suit a test that depends on what came before, which a `WHERE`,
looking at one row at a time, can't see. Here are the few hits that
make up half of all the plays, by a running total, and the albums a
job has still to do, after the one it stopped at last time:

```perl
use DBIx::Squirrel::Stages::Rows qw(pluck);
use DBIx::Squirrel::Stages::Flow qw(take_while drop_while drop);

my $half   = $dbh->selectrow_array('SELECT SUM(plays) FROM track') / 2;
my $so_far = 0;

my @hits = $dbh->iterate(
    'SELECT name, plays FROM track ORDER BY plays DESC',
    take_while { $so_far < $half },          # until these make half
    sub { $so_far += $_->[1]; $_->[0] },
)->all;
say join ', ', @hits;    # Dancing Queen, Sunshine of Your Love, Girls & Boys

my $stopped_at = 'Arrival';    # saved by the last run

my @still_to_do = $dbh->iterate(
    'SELECT title FROM album ORDER BY year',
    pluck,
    drop_while { $_ ne $stopped_at },    # what's done already
    drop(1),                             # and the one it stopped at
)->all;
say join ', ', @still_to_do;    # Parklife, The Great Escape
```

`take_while` stops the run at Parklife, so no row after it is
fetched.

### Take the first, the last, or the only one, and go on

`take_first`, `take_last` and `take_single` pass on one value, and let
the stages after them go on working with it. `take_single` warns at a
second value, as `single` does. On a query of your own, `LIMIT 1`
fetches less; these are for a statement that others share, or that
has a name:

```perl
use DBIx::Squirrel::Stages::Flow qw(take_first take_last);

my $by_year = 'SELECT title FROM album ORDER BY year';

my @oldest = $dbh->iterate($by_year, take_first, sub { lc $_->[0] =~ s( \W+ )(-)xgr })->all;
say "@oldest";    # disraeli-gears

my @newest = $dbh->iterate($by_year, take_last, sub { lc $_->[0] =~ s( \W+ )(-)xgr })->all;
say "@newest";    # the-great-escape
```

### Catch errors in a stage, but let a stop through

A stop works by throwing an exception that the run catches. So a
stage that catches errors itself must pass a stop on, or the run won't
stop. A stop is an object, where an error from `die` with a message is
a string, so pass on any error that's an object:

```perl
use DBIx::Squirrel::Stop qw(Stop);
use experimental qw(try);

my @safe = $dbh->iterate(
    'SELECT name FROM artist ORDER BY id',
    sub ($row) {
        try {
            Stop() if $row->[0] eq 'Cream';
            return uc $row->[0];
        }
        catch ($e) {
            die $e if ref $e;    # a stop, or another error object
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
use DBIx::Squirrel::Gather qw(gather);

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
use DBIx::Squirrel::Stages::Rows qw(pluck);
use DBIx::Squirrel::Gather qw(gather);

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

my @lines = $dbh->iterate(
    'SELECT name FROM artist ORDER BY name',
    pluck,
    and_count,
)->all;
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
use DBIx::Squirrel::Gather qw(gather);

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
use DBIx::Squirrel::Stages::Rows qw(pluck);
use DBIx::Squirrel::Stages::Batch qw(batch collect);

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

## 8. Rows as objects

Arrays are quick, and hashes are clear, but both fail quietly: a typo
in `$row->{titel}` gives `undef`, and the program carries on.
`results` gives rows as objects instead, with a method for each
column. A misspelt method dies, at the line with the typo.

### Have a method for each column

Ask for `results` where you'd ask for `iterate`. It takes the same
arguments, and gives the same kind of iterator, with every method of
chapters 4 to 7. The methods are named after the columns, in lower
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

### Shape objects with stages

Stages see the objects, and the iterator's methods work as before.
`pluck` takes a column of an object too:

```perl
use DBIx::Squirrel::Stages::Rows qw(pluck);
use DBIx::Squirrel::Stages::Flow qw(drop_if);

my %owned = map { $_ => 1 } 'Arrival', 'Parklife';

my @wanted = $dbh->results(
    'SELECT title, year FROM album ORDER BY year',
    drop_if { $owned{ $_->title } },    # the albums you have already
    pluck('title'),
)->all;
say join ', ', @wanted;    # Disraeli Gears, The Great Escape
```

## 9. A function for each database and statement

DBIx::Squirrel::Sugar gives each database you name, and each
statement, a function of its own. No handle to pass around, no global
variable to set up first: the database is connected to when it's first
used, and the statement is prepared once, and kept.

### Name a database

Defined with `use`, the function is there as the program compiles, so
it can be called without parentheses. Called with nothing, it's the
handle. Called with a statement and values, it runs it. With stages,
it gives an iterator:

```perl
use DBIx::Squirrel::Stages::Rows qw(pluck);
use DBIx::Squirrel::Sugar database => {
    music => ['dbi:SQLite:dbname=music.db', '', '', {RaiseError => 1}],
};

say ref music;    # DBIx::Squirrel::db

my $sth = music 'SELECT name FROM artist WHERE id = ?', 1;
say $sth->fetchrow_arrayref->[0];    # Abba

my @names = music('SELECT name FROM artist ORDER BY id', pluck)->all;
say "@names";    # Abba Blur Cream
```

### Name a statement, with stages of its own

A statement's definition is its database, its SQL, and any stages it
always has. Called, it takes values, then any stages for that call
only:

```perl
use DBIx::Squirrel::Stages::Rows qw(pluck);
use DBIx::Squirrel::Sugar statement => {
    titles_by => [music => 'SELECT title FROM album WHERE artist_id = :artist ORDER BY year', pluck],
    album     => [music => 'SELECT * FROM album WHERE id = ?'],
};

my @titles = titles_by(artist => 2)->all;
say "@titles";    # Parklife The Great Escape

my @slugs = titles_by(artist => 2, sub { lc s( \W+ )(-)xgr })->all;
say "@slugs";    # parklife the-great-escape

say titles_by(artist => 2)->first;    # Parklife

my $it = titles_by artist => 1;
say ref $it;    # DBIx::Squirrel::Iterator

my $sth = album 1;
say $sth->fetchrow_hashref->{title};    # Arrival
```

Without stages, a statement gives its handle, executed. With stages,
its own or the call's, it gives an iterator.

### Define them as the program runs

`database` and `statement`, imported, define them while the program
runs, from configuration, say:

```perl
use DBIx::Squirrel::Stages::Rows qw(pluck);
use DBIx::Squirrel::Sugar qw(database statement);

database(archive => 'dbi:SQLite:dbname=music.db', '', '', {RaiseError => 1});
statement(artist_count => archive => 'SELECT COUNT(*) FROM artist', pluck);

say artist_count()->single;     # 3
say ref database('archive');    # DBIx::Squirrel::db
```

`database('archive')`, given just the name, is the handle, from
anywhere in the program.

### Mind the names you import

A statement's function goes in your package, so its name can't be one
your package has already, such as a stage you've imported. Defining it
croaks: "Expected no function of the name in main already (pluck)".
Name statements for what they read, as `titles_by`, or import fewer
names.

## 10. Caching and connections

### Prepare a statement once, wherever it's used

`prepare_cached` keeps the statement handle on the database handle, as
the DBI does, so the same SQL is prepared once. If an iterator is part
way through the cached handle, it's left alone, and a new handle takes
its place:

```perl
use DBIx::Squirrel::Stages::Rows qw(pluck);

my $sql   = 'SELECT name FROM artist ORDER BY id';
my $first = $dbh->prepare_cached($sql)->iterate(pluck);
my($name) = $first->next;
say $name;    # Abba

my $second = $dbh->prepare_cached($sql)->iterate(pluck);
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

## 11. Functions that take stages, and stages for others

This is where stages pay off most. A function that runs a query can
take stages from its caller, and hand them on. It no longer needs an
option for "only the first ten", "just the names" or "not that one": its
caller writes those as stages, beside the call, and the function stays
the size of what only it knows, the SQL.

### Let callers of your functions add stages

Pass the caller's stages to `iterate`, after your values. Your caller
then says what it wants of the rows, with the stages it gives and the
iterator's methods:

```perl
use DBIx::Squirrel::Stages::Rows qw(pluck);
use DBIx::Squirrel::Stages::Flow qw(drop_if);

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

say ref tracks_by('Blur');    # DBIx::Squirrel::Iterator

say join ', ', tracks_by('Blur', pluck('name'))->all;    # Girls & Boys, Parklife, Country House
say tracks_by('Blur', pluck('name'))->first;                # Girls & Boys

say join ', ', tracks_by(
    'Blur',
    pluck('name'),
    drop_if { $_ eq 'Parklife' },
)->all;
# Girls & Boys, Country House
```

Compared with options, a stage can do anything the caller needs, not
only what you thought of, and the caller already knows how stages
work. Part 2 adds a last stage, a sink, for a caller who wants a count
or a file instead of an iterator.

### Write a function that makes a stage

A stage for others is made by a function, as `take(10)` is, so the
function can check its options once, when it's called, rather than on
every row. `croakf`, from DBIx::Squirrel::Errors, reports a mistake at
your caller's line, when the module lists
`@DBIx::Squirrel::Errors::INTERNAL` as its `@CARP_NOT`. Keep any state
in a `gather` block, so it starts afresh on each run:

```perl
use DBIx::Squirrel::Stages::Rows qw(pluck);

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

my $chart = $dbh->iterate(
    'SELECT name FROM artist ORDER BY id',
    pluck,
    My::Stages::numbered_from(1),
);
say join ', ', $chart->all;           # 1. Abba, 2. Blur, 3. Cream
say join ', ', $chart->reset->all;    # 1. Abba, 2. Blur, 3. Cream

eval { My::Stages::numbered_from('one') };
print $@;    # Expected a whole number to start from (one) at ... line ...
```

### Publish a module of stages

Name it for its job, in the namespace where its stages belong, and
name the distribution after it, as `DBIx-Squirrel-Stages-CSV` for
`DBIx::Squirrel::Stages::CSV`. Have it require the DBIx::Squirrel it
was tested with. The reference's [Stages for
others](REFERENCE.md#stages-for-others) has the details, and [chapter
21](#21-stages-beyond-the-database) says where a stage that doesn't
need a database belongs.

## 12. When things go wrong

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

## 13. Questions you may have

### Do I have to give up the DBI?

No. Every handle is a DBI handle, every DBI method works, and any
driver the DBI supports works. Where DBIx::Squirrel and plain DBI do
the same thing, they give the same result. You can add it to a program
one query at a time, and take a handle you already have ([chapter
1](#1-still-the-dbi)). The tests run on SQLite, MySQL and PostgreSQL.

### When should I use it, and when not?

The rest of this guide says what DBIx::Squirrel can do; this says when
it's worth it. The stages are more to learn, and they pay that back in
some code, not all of it.

**One query, used once, its rows used at once: the DBI's methods.** A
`selectall_arrayref`, or a `fetchrow_hashref` loop, says all there is
to say, and stages would only add words. That isn't leaving
DBIx::Squirrel: the handle is a DBI handle, so the DBI's methods are
there beside the rest, with placeholders in any style.

**Work the database can do: SQL.** For the first ten rows, write
`LIMIT 10`, not `take(10)`; for the rows that match, write `WHERE`,
not `take_if`. Sorting, grouping, joining and filtering a large table
belong in the query, where the database can use its indexes and send
fewer rows. Stages aren't a way to tune a query. As a rule: shaping
that belongs to the query goes in SQL, and shaping that belongs to the
caller goes in stages.

**One query, many callers: stages.** When a query stays the same but
what's done with its rows varies, write it once, in a function that
takes stages, and let each caller say what it wants: a count, the
first few, a column, some rows and not others ([Let callers of your functions add
stages](#let-callers-of-your-functions-add-stages)). The function
needn't change for a caller it didn't foresee. That's where the extra
words pay for themselves, and why the package suits reports, exports
and loads, command-line tools over a database, admin scripts, and
modules whose functions others call.

**Every caller wants a list: give them one.** A function whose callers
all call `all` holds every row each time, so its rows don't stream
anyway. `all` isn't wrong; often it's what's wanted. But then offer
both, a function that takes stages and one that gives the
list, and let the caller choose:

```perl
use DBIx::Squirrel::Stages::Rows qw(pluck);
use DBIx::Squirrel::Stages::Flow qw(drop_if);

sub artist_names (@stages) {
    return $dbh->iterate('SELECT name FROM artist ORDER BY name', pluck, @stages);
}
sub all_artist_names () { return artist_names()->all }

say join ', ', all_artist_names();          # Abba, Blur, Cream
say artist_names(drop_if { m( \A A )x })->first;    # Blur
```

**Not everything is a stream.** Rows that flow, read once in order,
suit an iterator and stages. A table you look things up in wants a
hash, built once with a select method, and an answer you'll read
several times wants an array:

```perl
my %artist = map {@$_} @{ $dbh->selectall_arrayref('SELECT id, name FROM artist') };
say $artist{2};    # Blur
```

Making every query a stream would make code like that worse, not
better.

As a rough rule, choosing quickly:

| You have | Reach for |
|---|---|
| a simple query, and one simple use of its rows | the DBI's methods, on the same handle |
| a domain model, as objects and their relationships | an ORM, such as DBIx::Class |
| a query that stays the same, and callers that vary | DBIx::Squirrel's stages |

It's a simplification, but close to how the choice goes in practice.
The biggest gain isn't the loops the stages replace: it's that whoever
writes a query needn't guess how its callers will want the rows.

### How fast is it?

Close to the DBI where it does the DBI's work, and a little slower per
row where it does more. Timed on a real table of 297,848 narrow rows,
in SQLite, on Perl 5.36, each way in a process of its own, the best of
three runs, in seconds:

| How the rows are read | Seconds |
|---|---|
| the DBI's `fetchrow_arrayref`, in a loop | 0.073 |
| the DBI's `selectall_arrayref` | 0.092 |
| DBIx::Squirrel's `selectall_arrayref` | 0.092 |
| `iterate(...)->all` | 0.122 |
| `map` over `iterate(...)->all` | 0.144 |
| `next`, in a loop | 0.259 |
| `iterate(..., $stage)->all` | 0.437 |

On wide rows, 21,826 of them averaging 24 KB, fetching the data costs
far more than anything around it, and every one of those ways takes
between 0.13 and 0.20 seconds.

So: the select methods cost nothing over the DBI's. `all` with no stages
takes about a third longer than `selectall_arrayref`. A stage costs
about a microsecond a row; over a hundred thousand rows, that's a tenth
of a second, and on most queries it's lost in the time the database
takes. When every row of a big result is wanted, and only needs
changing, `map` over `all` is quickest. Use stages when you might not
need every row, when the result is too big to hold, or when the steps
should travel with the query.

### Will a large result fill my memory?

Not through an iterator. Rows are fetched a few at a time, up to 64,
and each goes through the stages and on its way before the next batch
is fetched. Only `all` and `all_arrayref` hold every result, because
that's what you asked for. To process a large table, read it with
`next`, and keep only what you need of each row.

The driver may hold the whole result, though. DBD::SQLite reads rows
as they're fetched, but DBD::Pg and DBD::mysql receive every row when
the statement is executed: a 200 MB result took about 200 MB with
either. With MySQL, give the `mysql_use_result` attribute, and the
driver reads rows as they're fetched:

<!-- not run -->
```perl
my $it = $mysql->iterate('SELECT * FROM big_table', {mysql_use_result => 1});
```

It ties up the connection until every row is read, or the statement
is finished. With PostgreSQL, declare a cursor in your SQL, and fetch
from it a batch at a time.

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
8](#8-rows-as-objects)). There's nothing to set up before your first
query.

### How does it compare with DBIx::Simple?

Both make the DBI pleasanter to use, and both fill a list of values
into the SQL: DBIx::Simple with its `(??)`, DBIx::Squirrel with `...`
in front of a placeholder. DBIx::Simple wraps a DBI handle in an
object of its own, with methods for getting results in various shapes.
DBIx::Squirrel extends the DBI's own handles instead, so existing DBI
code and modules take them as they are, and it adds placeholders in
any style, and stages, which DBIx::Simple doesn't have.

### What doesn't it do?

It doesn't generate SQL, describe schemas, manage migrations or run
queries in parallel. Transactions are the DBI's. A statement handle
runs one statement at a time, so two iterators can't read the same
handle at once ([chapter
4](#use-one-iterator-at-a-time-on-a-statement-handle)). And stages run
in Perl, so work the database can do, such as filtering and limiting,
is better done in SQL.

## Where you can stop

That's DBIx::Squirrel: placeholders in any style, values checked
before they reach the database, the iterator, and stages beside the
query, on handles that are still the DBI's. Row objects, the Sugar and
functions that take stages are conveniences built on them. If that
does what you need, you can stop here, and nothing else is needed.

Part 2 is for when the rows have somewhere else to go.

## Part 2: With Ekorn::Pipeline

Part 1 is the round trip to the database: a query sent, and its rows
read back. Part 2 is data crossing the database's edge: query results
written to files, JSON and CSV, loaded from them in batches, or sent
to several places in one run.

Stages began in DBIx::Squirrel, in 2024, as a way to change query
results as they're fetched. The pipeline behind them was useful, and
usable, well beyond database rows, so in 2026 it moved into a
distribution of its own,
[Ekorn::Pipeline](https://github.com/nukopian/Ekorn-Pipeline), and
DBIx::Squirrel kept what needs a database. Everything in Part 1 is
DBIx::Squirrel's own. What follows shows what the two give you
together.

It adds four things to what Part 1 showed:

- **sources,** where values come from other than a statement: a file,
  JSON, CSV, or an array;
- **sinks,** a last stage that says what a run gives back: every
  result, a count, or a file written;
- **feeds,** for pushing values into a pipeline as they arrive;
- **tees,** for sending each row somewhere else on the way through.

A DBIx::Squirrel iterator is one of Ekorn::Pipeline's sources, so
everything here works on query results as it stands, and Part 1's
stages work in Ekorn::Pipeline's pipelines.

## 14. Import everything from one place

Part 1 imported each stage from the DBIx::Squirrel module that makes
it. Part 2 adds Ekorn::Pipeline's sources, sinks and words, from
modules of their own. You needn't remember which:
DBIx::Squirrel::Tooling exports them all, DBIx::Squirrel's and
Ekorn::Pipeline's together, by the same tags as
Ekorn::Pipeline::Tooling, with two of DBIx::Squirrel's own:

| Tag | What it gives you | Made in |
|---|---|---|
| `:core` | `Stop` and `gather` | DBIx::Squirrel::Stop and ::Gather |
| `:flow` | `take`, `drop`, `take_if`, `take_while` and the rest | DBIx::Squirrel::Stages::Flow |
| `:batch` | `batch` and `collect` | DBIx::Squirrel::Stages::Batch |
| `:taps` | `peek`, `count_into`, `dump_to` and `tee` | DBIx::Squirrel::Stages::Taps |
| `:rows` | `pluck` and `as_hash` | DBIx::Squirrel::Stages::Rows |
| `:stages` | `:flow`, `:batch`, `:taps` and `:rows` | |
| `:context` | `iterator`, `result_number` and `result_original` | DBIx::Squirrel::Context |
| `:sources` | `from_array`, `from_file`, `from_fh` and `counter` | Ekorn::Pipeline::Sources |
| `:sinks` | `count_items`, `keep_all`, `keep_first`, `to_file` and the rest | Ekorn::Pipeline::Sinks |
| `:json` | `from_json`, `from_jsonl`, `to_json` and `to_jsonl` | Ekorn::Pipeline::JSON |
| `:csv` | `from_csv` and `to_csv` | Ekorn::Pipeline::CSV |
| `:words` | `pipeline`, `stage`, `source`, `generator`, `sink_one` and the rest | Ekorn::Pipeline::Factories |
| `:all` | all of the above | |

The examples in this part import what each uses from Tooling, by
name. Ask for what you need, by name or by tag, or for `:all`. Nothing
comes by default:

```perl
package My::Report {
    use DBIx::Squirrel::Tooling qw(:stages :sinks);
    my %on_my_phone = map { $_ => 1 } 'Dancing Queen', 'Parklife', 'Sunshine of Your Love';
    say $dbh->iterate(
        'SELECT name FROM track',
        drop_if { $on_my_phone{ $_->[0] } },    # what the database can't know
        count_items,
    );
    # 3
}
```

Each name is the very sub its own module exports, so it makes no
difference which you import it from. Where DBIx::Squirrel and
Ekorn::Pipeline both export a name, it's the same sub.

Tooling leaves three things out:

- what's for extending DBIx::Squirrel rather than using it, such as
  `croakf`, which you import from its own module when chapter 11 needs
  it;
- the Sugar, whose `use` makes functions for your databases and
  statements, as chapter 9 explains;
- `|`, which only `use Ekorn::Pipeline::Operators` puts in force, in
  its own scope, as chapter 20 explains.

## 15. Sinks: saying what you want back

In Part 1, `iterate` always gave an iterator, and you asked it for
rows with `next`, `first`, `single` or `all`. A *sink* is another
way to say what you want back: a last stage that decides what the run
gives. Give one last, and `iterate` reads the run through and gives
you the sink's result, not an iterator.

The sinks are Ekorn::Pipeline's, from Ekorn::Pipeline::Sinks.
DBIx::Squirrel::Tooling's `:sinks` exports them all, as [chapter
14](#14-import-everything-from-one-place)'s import does.

### Get every result, or how many

`keep_all` gives every result: a list, or, where one value is asked
for, an array reference. `count_items` gives how many there were:

```perl
use DBIx::Squirrel::Tooling qw(pluck keep_all count_items);

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

my $words = $dbh->iterate('SELECT name FROM track', sub { split ' ', $_->[0] }, count_items);
say $words;    # 16
```

`count_items` counts what comes out of the stages, which SQL's `COUNT`
can't: here, the words in the tracks' names. For a count of rows, ask
the database, with `SELECT COUNT(*)`.

So `my $rows = ...` is the rows, never a count by accident: if you
want a count, say so with `count_items`. An empty result is an empty
array reference, which is true, so test it with `@$rows`.

### Get the first, the last, or the only one

`keep_first` gives the first result, and stops the run there.
`keep_last` reads every result, and gives the last. `keep_single`
gives the only one, warning at a second, as `single` does. Each gives
`undef` if there are none:

```perl
use DBIx::Squirrel::Tooling qw(pluck keep_first keep_last keep_single);

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

`keep_last` still fetches every row, as a database hands them over in
order, from the first. For the last row, ask the database: reverse the
`ORDER BY`, and add `LIMIT 1`. Without an `ORDER BY`, a query's rows
come in no order, so none of them is the last:

```perl
say $dbh->selectrow_array('SELECT name FROM track ORDER BY plays ASC LIMIT 1');    # Country House
```

### Keep the first few

`keep(N)` keeps the first N results, and stops the run once it has
them, so no more rows are fetched:

```perl
use DBIx::Squirrel::Tooling qw(pluck keep);

my @top = $dbh->iterate(
    'SELECT name FROM track ORDER BY plays DESC',
    pluck('name'),
    keep(3),
);
say join ', ', @top;    # Dancing Queen, Sunshine of Your Love, Girls & Boys
```

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
| them in a CSV file | | `to_csv(file => $path, header => 1)` |

Use a method when you have an iterator in hand, or have already read
some of it: the methods take whatever's left. Use a sink when the call
should say, all at once, what it gives. It's the only way to have a
count. It's also what you give a function, or a named statement, that
takes stages from its caller ([chapter
9](#9-a-function-for-each-database-and-statement), [chapter
11](#11-functions-that-take-stages-and-stages-for-others)). `all`
without stages is quicker, as it fetches every row in one go.

### End a caller's stages with a sink

Part 1's function that takes stages, and its named statements, take a
sink as they take any stage, given last. Neither needed changing for
it:

```perl
use DBIx::Squirrel::Tooling qw(count_items pluck keep_first);

say tracks_by('Abba', count_items);                     # 2
say titles_by(artist => 2, count_items);                # 2
say tracks_by('Blur', pluck('name'), keep_first);       # Girls & Boys
```

So one function, written once in Part 1's terms, gives an iterator, a
count, the first result or a file, as each caller asks.

## 16. Files, JSON and CSV

A query's results can go to a file in one call, with a sink given last,
and a file can come in the same way, through a source. Either way, a
few rows at a time are held, however large the file or the result.

### Write the results to a file

`to_file` writes each result to a file, a line each, and gives how
many it wrote. It closes the file however the run ends:

```perl
use DBIx::Squirrel::Tooling qw(pluck to_file);

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

For a spreadsheet, `to_csv`, from Tooling's `:csv`, writes each row as
a line of CSV. With `header => 1`, the first line is the statement's
column names, so the file says what's in it, and fields holding a
comma or a quote are quoted, so it reads back as it was:

```perl
use DBIx::Squirrel::Tooling qw(to_csv);

my $exported = $dbh->iterate(
    'SELECT name, plays FROM track WHERE plays > 6000 ORDER BY plays DESC',
    to_csv(file => 'hits.csv', header => 1),
);
say $exported;    # 3

open my $in, '<', 'hits.csv' or die "Can't read hits.csv: $!";
my @lines = <$in>;
close $in;
print @lines;
# name,plays
# "Dancing Queen",9100
# "Sunshine of Your Love",7700
# "Girls & Boys",6100
```

`to_csv` gives how many rows it wrote, not counting the header. It
needs [Text::CSV](https://metacpan.org/pod/Text::CSV), which
DBIx::Squirrel recommends, rather than requires; it's loaded only when
`to_csv` or `from_csv` is called. Rows may be arrays, as here, or
hashes, written in the header's order. After `as_hash` with columns,
as in `as_hash(qw(name plays))`, name them in the header too,
`header => [qw(name plays)]`: `header => 1` names every column the
statement has. `csv => {sep_char => "\t"}` writes TSV. [Load a CSV
file into a table](#load-a-csv-file-into-a-table) goes the other way.

### Write the results as JSON, and read them back

`to_json`, from Tooling's `:json`, writes every result as one JSON
array, and gives how many it wrote. Make each row a hash first, with
`as_hash`, and each is an object keyed by its column names:

```perl
use DBIx::Squirrel::Tooling qw(as_hash to_json);

my $saved = $dbh->iterate(
    'SELECT name, plays FROM track WHERE plays > 6000 ORDER BY plays DESC',
    as_hash,
    to_json(file => 'hits.json', json => {canonical => 1}),    # keys in order
);
say $saved;    # 3

open my $in, '<', 'hits.json' or die "Can't read hits.json: $!";
my @json = <$in>;
close $in;
print @json;
# [{"name":"Dancing Queen","plays":9100},{"name":"Sunshine of Your Love","plays":7700},{"name":"Girls & Boys","plays":6100}]
```

`from_json` reads it back, as a source: each element of the array, a
hash, goes through the stages in turn. `pluck` by name works on hashes
from anywhere, as it reads their keys:

```perl
use DBIx::Squirrel::Tooling qw(pluck from_json);
use Ekorn::Pipeline;

my @names = Ekorn::Pipeline->new(pluck('name'))->iterator(from_json(file => 'hits.json'))->all;
say join ', ', @names;    # Dancing Queen, Sunshine of Your Love, Girls & Boys
```

`json` takes options for the encoder, such as `pretty => 1`, or an
encoder of your own. `to_jsonl` and `from_jsonl` write and read JSON
Lines, an object a line, which suits a log or a file read as it grows.
All four need JSON::MaybeXS, which Ekorn::Pipeline requires.
[Load a CSV file into a table](#load-a-csv-file-into-a-table) explains
`iterator`.

### Load a CSV file into a table

A file needs no feed: `from_csv`, from Tooling's `:csv`, is a source,
reading a row at a time as the pipeline asks. With `header => 1`, each
row is a hash keyed by the header's names, and `munge => 'db'` makes
those names into ones a database takes, so "Track Name" is
`track_name`. Name the statement's placeholders the same, and each
row goes in as it was read, with no arrays to build and no columns to
count:

```perl
use DBIx::Squirrel::Tooling qw(drop_if batch from_csv);
use Ekorn::Pipeline;

# A file as a spreadsheet saves it, its header in a person's words
open my $out, '>', 'this-week.csv' or die "Can't write this-week.csv: $!";
print $out <<~'CSV';
    Track Name,Plays This Week
    Parklife,12
    "Knowing Me, Knowing You",3
    Country House,0
    Girls & Boys,7
    CSV
close $out;

$dbh->do('CREATE TEMP TABLE this_week (track_name TEXT, plays_this_week INTEGER)');
my $insert = $dbh->prepare(
    'INSERT INTO this_week (track_name, plays_this_week) VALUES (:track_name, :plays_this_week)',
);

my @written = Ekorn::Pipeline->new(
    drop_if { $_->{plays_this_week} == 0 },    # the file's rows, before the database has them
    batch(500),
    sub {
        my @rows = @$_;
        $dbh->begin_work;
        my $written = $insert->execute_for_fetch(sub { shift @rows });
        $dbh->commit;
        $written;
    },
)->iterator(from_csv(file => 'this-week.csv', header => 1, munge => 'db'))->all;
say "@written";    # 3

say $dbh->selectrow_array('SELECT SUM(plays_this_week) FROM this_week');    # 22
```

It reads the file a row at a time, and writes it 500 rows at a time,
each batch in a transaction, so a file of a million rows needs no more
memory than a batch of them. A row that won't parse croaks, naming its
record and field, rather than ending the load early as if the file had
ended. `from_csv` needs Text::CSV, as `to_csv` does (see [Write the
results to a file](#write-the-results-to-a-file)). `header => 'skip'`
reads the rows as arrays, for `?` placeholders, and `csv => {sep_char
=> "\t"}` reads TSV. Ekorn::Pipeline::CSV's documentation has the rest.

The load is a pipeline, `Ekorn::Pipeline->new(...)`, run over the file
by its `iterator`. Given a source, such as `from_csv`'s, `iterator`
gives an iterator over what comes out of the pipeline's stages, much
as `iterate` does for a query: `all`, `first` and `single` work as they
do on a query's, and the next value comes from calling it, as
`$it->()`, where a query's has `next`. Here the stage that writes each
batch gives how many it wrote, so `all` gives one count a batch.

## 17. Building pipelines from pipelines

The stages given to a call are a *pipeline*: a list of stages, run in
order. You can make one yourself, with `Ekorn::Pipeline->new`, and it
goes wherever a stage goes, standing for its stages. So a set of steps
you use often can be made once, named, and used everywhere.

### Make a pipeline once, and use it anywhere

```perl
use DBIx::Squirrel::Tooling qw(drop_if pluck take);
use Ekorn::Pipeline;

my %on_my_phone = map { $_ => 1 } 'Dancing Queen', 'Parklife', 'Sunshine of Your Love';

my $to_copy = Ekorn::Pipeline->new(
    drop_if { $on_my_phone{ $_->[0] } },    # what the phone has already
    pluck('name'),
);

my $by_plays = 'SELECT name, plays FROM track ORDER BY plays DESC';
say join ', ', $dbh->iterate($by_plays, $to_copy)->all;
# Girls & Boys, Knowing Me, Knowing You, Country House
say join ', ', $dbh->iterate(
    $by_plays,
    $to_copy,
    take(2),
)->all;
# Girls & Boys, Knowing Me, Knowing You
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
they croak "Expected a statement to read, for the column names".
`pluck` by name on hashes, which reads their keys, works anywhere.

### Make a stage out of others

A function can return a pipeline, made of other stages. It goes
wherever a stage goes, and works on each shape of row the stages in it
do:

```perl
use DBIx::Squirrel::Tooling qw(pluck);
use Ekorn::Pipeline;

sub with_origin () {
    my %from = (Abba => 'Sweden', Blur => 'England', Cream => 'England');
    return Ekorn::Pipeline->new(
        pluck('name'),
        sub { "$_ ($from{$_})" },
    );
}

say join ', ', $dbh->iterate('SELECT id, name FROM artist ORDER BY id', with_origin)->all;
# Abba (Sweden), Blur (England), Cream (England)
say join ', ', $dbh->results('SELECT id, name FROM artist ORDER BY id', with_origin)->all;
# Abba (Sweden), Blur (England), Cream (England)
```

### Choose the stages for each run

The stage a `gather` block returns can be a whole pipeline, built for
the run. So the block can choose its stages as each run starts:

```perl
use DBIx::Squirrel::Tooling qw(gather take);
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

### Name a pipeline, and use it by name

`Ekorn::Pipeline->named` names a pipeline, for the rest of the
program. `pipeline`, from Ekorn::Pipeline::Factories, makes a pipeline
from stages and names, and is the shortest way to say "this named
pipeline, then these":

```perl
use DBIx::Squirrel::Tooling qw(pipeline take);
use Ekorn::Pipeline;

Ekorn::Pipeline->named(slug => sub { lc $_->[0] =~ s( \W+ )(-)xgr });

say join ', ', $dbh->iterate('SELECT title FROM album ORDER BY year', pipeline('slug'))->all;
# disraeli-gears, arrival, parklife, the-great-escape
say join ', ', $dbh->iterate('SELECT title FROM album ORDER BY year', pipeline('slug', take(1)))->all;    # disraeli-gears
```

A name belongs to the package that named it, so two modules can each
have a `clean` of their own. A name is looked up when the pipeline is
made, so name it first. The Sugar's statements take names too
([chapter 9](#9-a-function-for-each-database-and-statement)).

### Use a named pipeline in a definition

A statement's definition can name a pipeline. Give the pipelines to
the same `use`, after `pipeline`. They're named before any statement
is defined, wherever they're given, so a statement can name one beside
it. Each gets a function of its name too. When the statement is
called, a string is always a value, never a name:

```perl
use DBIx::Squirrel::Tooling qw(keep_all);
use DBIx::Squirrel::Sugar
    statement => {
        title_slugs => [music => 'SELECT title FROM album WHERE year < ? ORDER BY year', 'slugged'],
    },
    pipeline => {slugged => [sub { lc $_->[0] =~ s( \W+ )(-)xgr }]};

say join ', ', title_slugs(1990, keep_all);    # disraeli-gears, arrival
say slugged(['The Great Escape']);             # the-great-escape
```

`pipeline` takes what Ekorn::Pipeline::Sugar takes: a hash, or an
array of names and stages in turn. A name is looked up as the
statement is defined, so a pipeline named another way, with
`Ekorn::Pipeline->named`, must be named in a `BEGIN` block above a
statement defined with `use`.

### Run a handle through stages

`pipe` runs a database or statement handle itself through stages, and
gives back what comes out. `tap` does the same for the stages' side
effects, and gives back the handle, so a chain of calls can carry on:

```perl
my %from = (Abba => 'Sweden', Blur => 'England', Cream => 'England');    # from a config file

my @names = $dbh->pipe(
    sub ($dbh) { @{ $dbh->selectcol_arrayref('SELECT name FROM artist ORDER BY id') } },
    sub { "$_ ($from{$_})" },
);
say join ', ', @names;    # Abba (Sweden), Blur (England), Cream (England)

my $albums = $dbh->tap(sub ($dbh) { say 'albums: ', $dbh->selectrow_array('SELECT COUNT(*) FROM album') })
    ->selectrow_array('SELECT COUNT(*) FROM album WHERE year > 1990');
say "since 1990: $albums";
# albums: 4
# since 1990: 2
```

`tap` is handy for logging or checking something on the way through,
without breaking up a chain of method calls.

## 18. Loading rows as they arrive

### Load rows as they arrive

`$pipeline->feed` starts one run of a pipeline and gives it to you,
to push values into as they arrive: lines read from a socket, records
a callback hands you, or rows from somewhere other than a statement.
Each `push` gives back what came out of the values pushed. `close`
ends the input, and gives what the stages still held, such as a last,
part-filled batch. `ended` says how the run ended. For a file, there's
a source instead: see [Load a CSV file into a
table](#load-a-csv-file-into-a-table).

So a feed is a loader. Here records go into a table two at a time,
each batch in a transaction of its own. The records are hashes, and
the statement's placeholders are named, so `execute_for_fetch` writes
each as it came, with no arrays to build:

```perl
use DBIx::Squirrel::Tooling qw(drop_if batch);
use Ekorn::Pipeline;

$dbh->do('CREATE TEMP TABLE heard (track_id INTEGER, plays INTEGER)');
my $insert = $dbh->prepare('INSERT INTO heard (track_id, plays) VALUES (:track_id, :plays)');

my $load = Ekorn::Pipeline->new(
    drop_if { $_->{plays} == 0 },
    batch(2),
    sub {
        my @records = @$_;
        $dbh->begin_work;
        my $written = $insert->execute_for_fetch(sub { shift @records });
        $dbh->commit;
        $written;    # how many were written
    },
)->feed;

my @written;
push @written, $load->push($_)
    for {track_id => 1, plays => 3}, {track_id => 2, plays => 0},
        {track_id => 3, plays => 5}, {track_id => 4, plays => 1};
push @written, $load->close;
say "@written";         # 2 1
say $load->ended;       # done
say $dbh->selectrow_array('SELECT COUNT(*) FROM heard');    # 3
```

The first batch is written in the push that fills it, and the last, of
one row, by `close`. A stop, such as `take`'s, ends the run in the push
that meets it, and a push after that croaks, so ask `ended` after each
push when a stop may come. Ekorn::Pipeline's [how-to on
feeds](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/HOWTO.md#feed-values-in-as-they-arrive)
has the rest.

`execute_for_fetch` takes arrays too, a value for each placeholder,
in the order each name first appears. So does `execute_array`, an
array for each placeholder, and `bind_param_array` binds one by name,
as the reference's [execute_array](REFERENCE.md#execute_array) says.
Plain DBI's take only `?`, and other styles as far as the driver reads
them.

## 19. Several places in one run

`tee`, from DBIx::Squirrel::Stages::Taps on request, sends each row
somewhere else on the way through. It runs each row through stages of
its own, beside the pipeline, and passes the row on as it came. So one
run of a query can write a file and give its results too, without the
query running twice:

```perl
use DBIx::Squirrel::Tooling qw(tee to_csv take_if pluck keep_all);

my @hits = $dbh->iterate(
    'SELECT name, plays FROM track ORDER BY plays DESC',
    tee(to_csv(file => 'played.csv', header => 1)),    # every track, to a file
    take_if { $_->[1] > 6000 },
    pluck('name'),
    keep_all,
);
say join ', ', @hits;    # Dancing Queen, Sunshine of Your Love, Girls & Boys

open my $in, '<', 'played.csv' or die "Can't read played.csv: $!";
my @lines = <$in>;
close $in;
say scalar @lines;    # 7
```

The file has a line for each of the six tracks, and its header, though
the run gave only three. A tee's stages can pick out some rows, stop
early, or use `pluck`, as the pipeline's can:

```perl
use DBIx::Squirrel::Tooling qw(tee take pluck count_items);

my @first_two;
my $count = $dbh->iterate(
    'SELECT name FROM artist ORDER BY name',
    tee(take(2), pluck('name'), sub { push @first_two, $_; () }),
    count_items,
);
say "@first_two, of $count";    # Abba Blur, of 3
```

A stop in `tee`'s stages, such as `take(2)`'s, ends only them: the
pipeline reads on. It costs a good deal more than `peek`, so keep it
for side jobs and debugging.

A stop after the tee, such as `take`'s, or an iterator's `first`,
ends the branch too, and the branch's stages hand over what they
hold, as they do when the rows run out. So a branch writing rows in
batches writes the last, part-filled one, however the run ends.

## 20. Chaining with | and @{}

Some queries read best as one line, left to right: the statement, then
what's done to its rows, then what comes back. With
Ekorn::Pipeline::Operators in force, an iterator takes `|`, and so
does what it makes:

```perl
use DBIx::Squirrel::Tooling qw(pluck drop_if take keep_all count_items);
use Ekorn::Pipeline::Operators;

my %on_my_phone = map { $_ => 1 } 'Dancing Queen', 'Parklife', 'Sunshine of Your Love';

my $next = $dbh->iterate('SELECT name FROM track ORDER BY plays DESC')
    | pluck('name')
    | drop_if { $on_my_phone{$_} }
    | take(2)
    | keep_all;
say join ', ', @$next;    # Girls & Boys, Knowing Me, Knowing You

my $n = $dbh->iterate('SELECT name FROM track') | sub { split ' ', $_->[0] } | count_items;
say $n;    # 16
```

The operators are in force only in the scope that says
`use Ekorn::Pipeline::Operators`. Elsewhere, `|` on an iterator
croaks, so a chain is never mistaken for Perl's own bitwise or.

### `|` always gives one value

This is the one thing to remember about `|`. Perl calls an operator
for exactly one value, so a chain ending in `keep_all` gives an array
reference, even assigned to an array:

```perl
use DBIx::Squirrel::Tooling qw(pluck keep_all);
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
use DBIx::Squirrel::Tooling qw(pluck);
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

## 21. Stages beyond the database

A stage is a plain sub, and a pipeline runs it over values from
anywhere, not only rows. So the habits Part 1 taught, a function that
takes stages from its caller, and stages made by functions, work for
any function, with or without a database. Ekorn::Pipeline's [user
guide](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/HOWTO.md)
starts from the beginning, and shows how to write sources and sinks
of your own.

### Take stages for values that don't come from a database

The same idea works for any function, with values from anywhere: make
a pipeline of the caller's stages, and call it with your values:

```perl
use DBIx::Squirrel::Tooling qw(pluck);
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

### Tell a stop from other errors by its class

[Chapter 6](#catch-errors-in-a-stage-but-let-a-stop-through) passes
on any error that's an object, as a stop is one. To pass on only
stops, and handle other error objects, test for the class every stop
belongs to, Ekorn::Pipeline::Stop, whether it was thrown with `Stop`,
or by a stage such as `take`:

```perl
use DBIx::Squirrel::Tooling qw(Stop);
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

## 22. Coming from version 1 or 2

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
- **DBIx::Squirrel::Pipeline is no longer shipped.** Make pipelines
  with `Ekorn::Pipeline->new`. A copy that version 2 installed still
  loads, until it's deleted, as installing never removes a file.
  DBIx::Squirrel::Stop still exports `Stop`, but to throw a stop as a
  method, use `Ekorn::Pipeline::Stop->throw`.
- **A `gather` block's second part is its flush,** what version 2
  called the end function. It works as before. An end, told how the
  run ended, can follow it.

```perl
use DBIx::Squirrel::Tooling qw(pluck keep_all count_items);
use DBIx::Squirrel::Sugar statement => {
    every_artist => [music => 'SELECT name FROM artist ORDER BY id', pluck],
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
  9](#9-a-function-for-each-database-and-statement)).
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
use DBIx::Squirrel::Tooling qw(pluck keep_single);
use DBIx::Squirrel::Sugar statement => {
    artist_id => [music => 'SELECT id FROM artist WHERE name = ? LIMIT 1', pluck],
};

say artist_id('Blur', keep_single);    # 2
```
