# DBIx::Squirrel how-to

Recipes for everyday database work with DBIx::Squirrel, one task at a
time. Each shows the shortest way to do the job; [the
reference](REFERENCE.md) says what every method and attribute does, in
full.

This is version 2, a rewrite of DBIx::Squirrel 1.x for Perl 5.36 or
later. The reference's [Upgrading from 1.x](REFERENCE.md#upgrading-from-1x)
lists what changes for code written for 1.x.

## Contents

- [The examples' database](#the-examples-database)
- [Connecting](#connecting)
- [Writing statements](#writing-statements)
- [Binding values](#binding-values)
- [Running statements](#running-statements)
- [Iterating over results](#iterating-over-results)
- [Transforming rows with stages](#transforming-rows-with-stages)
- [Rows as objects](#rows-as-objects)
- [Pipelines without a database](#pipelines-without-a-database)
- [A function for each database and statement](#a-function-for-each-database-and-statement)
- [Caching](#caching)
- [Handling errors](#handling-errors)

## The examples' database

Every example below runs against this small SQLite database, a file
called `music.db`, set up here. The examples follow on from each other,
so `$dbh` is this handle wherever it appears.

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

## Connecting

### Connect to a database

`connect` takes what the DBI's takes. It always croaks if it can't
connect, so there's no `or die` to write.

<!-- not run -->
```perl
my $pg    = DBIx::Squirrel->connect('dbi:Pg:dbname=music', $user, $pass, {RaiseError => 1});
my $mysql = DBIx::Squirrel->connect('dbi:mysql:database=music', $user, $pass);
```

With no username or password, the attributes can follow the data source
straight away:

```perl
my $music = DBIx::Squirrel->connect('dbi:SQLite:dbname=music.db', {RaiseError => 1});
```

### Use a handle you already have

Code that already has a DBI handle can have a DBIx::Squirrel one with
the same connection parameters. It's a new connection, not a second
name for the first.

```perl
use DBI;

my $plain    = DBI->connect('dbi:SQLite:dbname=music.db', '', '', {RaiseError => 1});
my $squirrel = DBIx::Squirrel->connect($plain);

say ref $squirrel;    # DBIx::Squirrel::db
```

### Set defaults for every statement

Attributes starting `ekorn_` are DBIx::Squirrel's own. Given to
`connect`, they're the defaults for every statement the handle prepares.
Here, every iterator fetches rows as hashes:

```perl
my $hashes = DBIx::Squirrel->connect('dbi:SQLite:dbname=music.db', {
    RaiseError  => 1,
    ekorn_slice => {},
});

say $hashes->iterate('SELECT name FROM artist WHERE id = 1')->single->{name};    # Abba
```

### Import the DBI's constants

`use DBIx::Squirrel` takes whatever `use DBI` takes:

```perl
use DBIx::Squirrel qw(:sql_types);

say SQL_INTEGER;    # 4
```

### Read a database's quoting rules through ODBC

Statements are read by the database's own rules for strings and
comments. Through DBD::ODBC or DBD::Proxy, DBIx::Squirrel asks the
database what it is; when it can't tell, name it:

<!-- not run -->
```perl
my $dbh = DBIx::Squirrel->connect($odbc_dsn, $user, $pass, {ekorn_dialect => 'mysql'});
```

## Writing statements

### Use the placeholder style you like

Each of these is rewritten as `?` for the DBI. A statement uses one
style throughout.

```perl
my @styles = (
    'SELECT title FROM album WHERE year = ?',
    'SELECT title FROM album WHERE year = ?1',
    'SELECT title FROM album WHERE year = :1',
    'SELECT title FROM album WHERE year = $1',
    'SELECT title FROM album WHERE year = :year',
);
for my $sql (@styles) {
    my $sth = $dbh->prepare($sql);
    $sth->execute($sql =~ m( :year )x ? (year => 1994) : 1994);
    say $sth->fetchrow_arrayref->[0];    # Parklife, five times
}
```

### Use one value in several places

A numbered placeholder takes its value once, wherever it appears:

```perl
my $near = $dbh->selectcol_arrayref(
    'SELECT title FROM album WHERE year BETWEEN $1 - 1 AND $1 + 1 ORDER BY year',
    undef, 1995,
);
say "@$near";    # Parklife The Great Escape
```

So does a named one, wherever its name appears.

### Match any of a list of values

Put `...` before a placeholder, and give it an array reference: it's
written as a `?` for each value.

```perl
my $titles = $dbh->selectcol_arrayref(
    'SELECT title FROM album WHERE year IN (...:years) ORDER BY year',
    years => [1967, 1994],
);
say "@$titles";    # Disraeli Gears Parklife

# Alone, the array reference is the list
my $names = $dbh->selectcol_arrayref('SELECT name FROM artist WHERE id IN (...?)', [1, 3]);
say "@$names";    # Abba Cream
```

The statement is prepared for its values, so give them with it, to
`do`, a select method, `iterate` or `results`; `prepare` alone croaks.
An empty list croaks too, as `IN ()` isn't SQL, so check for one first.

### Write a long statement over several lines

Give the lines in an array reference; they're joined with spaces:

```perl
my $sth = $dbh->prepare([
    'SELECT title',
    'FROM album',
    'WHERE year < :year',
    'ORDER BY year',
]);
$sth->execute(year => 1990);
say $_->[0] for @{ $sth->fetchall_arrayref };    # Disraeli Gears, Arrival
```

### Keep quotes, comments and casts as they are

Placeholders are only looked for in the SQL itself, so these need no
escaping:

```perl
my $row = $dbh->selectrow_arrayref(
    q{SELECT '10:30', :name -- not :a placeholder},
    undef, name => 'Abba',
);
say "@$row";    # 10:30 Abba
```

On PostgreSQL, put a backslash before a `?`, `:` or `$` that's an
operator, such as jsonb's `?`:

<!-- not run -->
```perl
my $sth = $pg->prepare(q{SELECT * FROM doc WHERE data \? 'key' AND id = :id});
```

## Binding values

### Bind named values

As pairs, or in a hash reference, with or without the sigil:

```perl
my $sth = $dbh->prepare('SELECT title FROM album WHERE artist_id = :artist AND year >= :year');

$sth->execute(artist => 2, year => 1995);
say $sth->fetchrow_arrayref->[0];    # The Great Escape

$sth->execute({':artist' => 2, ':year' => 1995});
say $sth->fetchrow_arrayref->[0];    # The Great Escape
```

### Pass the values in an array reference

A single array reference stands for the values in it:

```perl
my @values = (2, 1995);
my $sth    = $dbh->prepare('SELECT title FROM album WHERE artist_id = ? AND year = ?');
$sth->execute(\@values);
say $sth->fetchrow_arrayref->[0];    # The Great Escape
```

With DBD::Pg, an array reference given to a statement taking one value
is a PostgreSQL array, as with the DBI:

<!-- not run -->
```perl
my $titles = $pg->selectcol_arrayref('SELECT title FROM album WHERE id = ANY(?)', [1, 2]);
```

### Bind first, execute later

```perl
my $sth = $dbh->prepare('SELECT name FROM track WHERE plays > :plays ORDER BY plays DESC');
$sth->bind(plays => 7000)->execute;
say $_->[0] for @{ $sth->fetchall_arrayref };    # Dancing Queen, Sunshine of Your Love
```

### Bind one value, with its type

`bind_param` takes a placeholder's name or number, and binds every use
of it:

```perl
use DBIx::Squirrel qw(:sql_types);

my $sth = $dbh->prepare('SELECT name FROM track WHERE plays > :plays ORDER BY plays DESC');
$sth->bind_param(':plays', 7000, SQL_INTEGER);
$sth->execute;
say $sth->fetchrow_arrayref->[0];    # Dancing Queen
```

## Running statements

### Change rows

`do` takes bind values without the attributes in front, and returns the
number of rows changed:

```perl
my $rows = $dbh->do('UPDATE track SET plays = plays + 1 WHERE album_id = :album', album => 1);
say $rows;    # 2: Arrival's two tracks, one play more each from here on
```

### Fetch one row

The DBI's select methods work as they do with the DBI, with
placeholders in any style, and, as with `do`, the attributes left out
when there are none. `selectrow_array` returns the first row's columns,
or, in scalar context, its first column:

```perl
my($title, $year) = $dbh->selectrow_array('SELECT title, year FROM album WHERE id = ?', 2);
say "$title ($year)";    # Parklife (1994)

my $tracks = $dbh->selectrow_array('SELECT COUNT(*) FROM track');
say $tracks;    # 6
```

`selectrow_arrayref` and `selectrow_hashref` return the row as an array
or a hash, or `undef` if there's none:

```perl
my $top = $dbh->selectrow_arrayref(
    'SELECT name, plays FROM track WHERE album_id = $1 AND plays > $2 ORDER BY plays DESC',
    1, 5000,
);
say "@$top";    # Dancing Queen 9101

my $artist = $dbh->selectrow_hashref('SELECT * FROM artist WHERE id = :id', id => 2);
say $artist->{name};    # Blur

my $nobody = $dbh->selectrow_hashref('SELECT * FROM artist WHERE name = :name', name => 'Queen');
say defined $nobody ? 'found' : 'no such artist';    # no such artist
```

### Fetch one column

`selectcol_arrayref` returns the first column of every row:

```perl
my $titles = $dbh->selectcol_arrayref('SELECT title FROM album WHERE artist_id = $1', 2);
say "@$titles";    # Parklife The Great Escape
```

With the DBI's `Columns` attribute, it returns those columns of each
row, one after the other, which makes a hash of two:

```perl
my %name = @{ $dbh->selectcol_arrayref('SELECT id, name FROM artist', {Columns => [1, 2]}) };
say $name{3};    # Cream
```

Named values in a hash reference need the attributes, or `undef`, in
front, as a hash reference there is taken as the attributes:

```perl
my $between = $dbh->selectcol_arrayref(
    'SELECT title FROM album WHERE year BETWEEN :from AND :to ORDER BY year',
    undef, {from => 1970, to => 1995},
);
say join ', ', @$between;    # Arrival, Parklife, The Great Escape
```

### Fetch every row

`selectall_arrayref` returns every row, each as an array, or, with the
DBI's `Slice` attribute, as a hash; `MaxRows` stops after that many:

```perl
my $rows = $dbh->selectall_arrayref(
    'SELECT name, plays FROM track WHERE plays >= ?1 ORDER BY plays DESC',
    7000,
);
say join ', ', map {"$_->[0] ($_->[1])"} @$rows;    # Dancing Queen (9101), Sunshine of Your Love (7700)

my $albums = $dbh->selectall_arrayref('SELECT title, year FROM album ORDER BY year', {Slice => {}});
say $albums->[0]{title};    # Disraeli Gears

my $first_two = $dbh->selectall_arrayref('SELECT name FROM artist ORDER BY name', {MaxRows => 2});
say scalar @$first_two;    # 2
```

`selectall_array` returns the rows as a list:

```perl
my $sql = 'SELECT title FROM album WHERE artist_id = :artist ORDER BY year';
for my $row ($dbh->selectall_array($sql, artist => 2)) {
    say $row->[0];    # Parklife, then The Great Escape
}
```

`selectall_hashref` returns the rows keyed by a column, or by several,
nested in order:

```perl
my $by_id = $dbh->selectall_hashref('SELECT id, name FROM artist', 'id');
say $by_id->{3}{name};    # Cream

my $by_artist = $dbh->selectall_hashref(
    'SELECT artist.name AS artist, title, year FROM album JOIN artist ON artist.id = album.artist_id',
    ['artist', 'title'],
);
say $by_artist->{Blur}{Parklife}{year};    # 1994

my $since = $dbh->selectall_hashref('SELECT id, title FROM album WHERE year >= $1', 'title', 1990);
say join ', ', sort keys %$since;    # Parklife, The Great Escape
```

### Select with a statement handle, lines or an array of values

Each select method also takes a statement handle, prepared once, a
statement over several lines, or its values in an array reference:

```perl
my $sth = $dbh->prepare('SELECT name FROM track WHERE album_id = :album ORDER BY name');
say join ', ', @{ $dbh->selectcol_arrayref($sth, album => 2) };    # Girls & Boys, Parklife
say join ', ', @{ $dbh->selectcol_arrayref($sth, album => 1) };    # Dancing Queen, Knowing Me, Knowing You

my $popular = $dbh->selectrow_array(
    ['SELECT COUNT(*)', 'FROM track', 'WHERE plays > $1'],
    5000,
);
say $popular;    # 4

my($escape) = $dbh->selectrow_array('SELECT title FROM album WHERE artist_id = ? AND year = ?', [2, 1995]);
say $escape;    # The Great Escape
```

### Finish an active statement before running it again

With `ekorn_finish_active`, executing a statement that still has rows
to fetch finishes it first:

```perl
my $sth = $dbh->prepare('SELECT name FROM artist ORDER BY id', {ekorn_finish_active => 1});
$sth->execute;
$sth->fetchrow_arrayref;    # one row read, two left
$sth->execute;              # finished, then executed again
say $sth->fetchrow_arrayref->[0];    # Abba
```

## Iterating over results

### Loop over the rows

```perl
my $it = $dbh->iterate('SELECT name FROM artist ORDER BY name');
while (my($row) = $it->next) {
    say $row->[0];    # Abba, Blur, Cream
}
```

Read `next` in list context, as here, so a result that is `undef` isn't
taken for the end.

### Stop when you've had enough

The statement is fetched 100 rows at a time, so leaving early never
reads the rest:

```perl
my $it = $dbh->iterate('SELECT name FROM track ORDER BY plays DESC');
while (my($row) = $it->next) {
    say $row->[0];    # Dancing Queen, Sunshine of Your Love
    last if $it->count == 2;
}
```

### Get every result at once, or count them

```perl
my @names = $dbh->iterate('SELECT name FROM artist', sub { $_->[0] })->all;
my $count = $dbh->iterate('SELECT name FROM artist')->all;    # scalar context

say "@names";    # Abba Blur Cream
say $count;      # 3
```

Without stages, `all` fetches the rest of the rows at once, nearly as
quickly as the DBI's own `selectall_arrayref`. Stages cost a little for
each row, so for a large result, when every row is wanted and only
needs changing, `map` over `all` is quicker:

```perl
my @fast = map { $_->[0] } $dbh->iterate('SELECT name FROM artist')->all;
say "@fast";    # Abba Blur Cream
```

### Get exactly one result

`single` returns the one result, or nothing, and croaks if there's more
than one:

```perl
my $total = $dbh->iterate('SELECT SUM(plays) FROM track', sub { $_->[0] })->single;
say $total;    # 36802
```

### Fetch rows as hashes

```perl
my $it = $dbh->iterate('SELECT id, name FROM artist ORDER BY id', {ekorn_slice => {}});
while (my($row) = $it->next) {
    say "$row->{id}: $row->{name}";    # 1: Abba, 2: Blur, 3: Cream
}
```

### Run one statement for several values

Prepare it once, and iterate over it with each value:

```perl
my $sth = $dbh->prepare('SELECT title FROM album WHERE artist_id = ? ORDER BY year');
for my $artist_id (1, 2) {
    my @titles = $sth->iterate($artist_id, sub { $_->[0] })->all;
    say "$artist_id: @titles";    # 1: Arrival, 2: Parklife The Great Escape
}
```

### Start an iterator again from the top

`reset` executes the statement again. Bind values given replace those
given before; stages given are added to those given when the iterator
was made.

```perl
my $it = $dbh->iterate('SELECT name FROM artist WHERE id > ? ORDER BY id', 0, sub { $_->[0] });

say join ' ', $it->all;                         # Abba Blur Cream
say join ' ', $it->reset(1)->all;               # Blur Cream
say join ' ', $it->reset(sub { lc })->all;      # blur cream
```

## Transforming rows with stages

A stage is a code reference given after the bind values. Each row goes
through every stage in turn, and what comes out of the last is the
result. A stage gets its value as its argument and in `$_`, so write it
whichever way reads best:

```perl
my @a = $dbh->iterate('SELECT name FROM artist', sub ($row) { $row->[0] })->all;
my @b = $dbh->iterate('SELECT name FROM artist', sub { $_->[0] })->all;

say "@a" eq "@b" ? 'the same' : 'different';    # the same
```

The recipes here are for rows. Ekorn::Pipeline's [how-to](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/HOWTO.md) has
more, for stages over any values, and they work here too, with
DBIx::Squirrel's names for its modules.

### Change each row (map)

Return one value:

```perl
my @lines = $dbh->iterate(
    'SELECT title, year FROM album ORDER BY year',
    sub { "$_->[0] ($_->[1])" },
)->all;
say for @lines;    # Disraeli Gears (1967), Arrival (1976), ...
```

### Leave rows out (filter)

Return nothing:

```perl
my @hits = $dbh->iterate(
    'SELECT name, plays FROM track',
    sub { $_->[1] >= 6000 ? $_ : () },
    sub { $_->[0] },
)->all;
say "@hits";    # Dancing Queen Girls & Boys Sunshine of Your Love
```

### Turn one row into several (flatMap)

Return a list:

```perl
my @words = $dbh->iterate(
    'SELECT title FROM album ORDER BY year',
    sub { split ' ', $_->[0] },
    sub { lc },
)->all;
say "@words";    # disraeli gears arrival parklife the great escape
```

### Stop early, from a stage

`Stop` ends the iteration. The results already out are kept, and any
values given to `Stop` go on through the stages after it:

```perl
use DBIx::Squirrel::Stop;

my @upto = $dbh->iterate(
    'SELECT title, year FROM album ORDER BY year',
    sub { $_->[1] >= 1990 ? Stop($_) : $_ },    # this one, then no more
    sub { $_->[0] },
)->all;
say "@upto";    # Disraeli Gears Arrival Parklife
```

### Take the first few, or drop some, after a stage

`take`, `drop`, `take_while` and `drop_while`, from
DBIx::Squirrel::Stages::Flow, decide which values go on, by their place
or by a test. In plain SQL, `LIMIT` and `OFFSET` do the first two in
the database; these are for when a stage in Perl decides which rows go
on, or for `pipe`. `take` stops the iteration once it has its values,
so no more rows are fetched:

```perl
use DBIx::Squirrel::Stages::Flow qw(:DEFAULT take_while);

my @page = $dbh->iterate(
    'SELECT name FROM track ORDER BY id',
    sub { $_->[0] },
    sub { m( \s )x ? $_ : () },    # names of more than one word
    drop(1), take(2),              # the second and third of them
)->all;
say for @page;    # Knowing Me, Knowing You
                  # Girls & Boys

my @hits = $dbh->iterate(
    'SELECT name, plays FROM track ORDER BY plays DESC',
    take_while { $_->[1] > 6000 },
    sub { $_->[0] },
)->all;
say join ', ', @hits;    # Dancing Queen, Sunshine of Your Love, Girls & Boys
```

### Take one column, or make rows hashes

`pluck` and `as_hash`, from DBIx::Squirrel::Stages::Rows, work whatever
shape the rows were fetched in. `pluck` takes a column by name, in any
case, or by position, from 0; `as_hash` gives each row as
`fetchrow_hashref` would:

```perl
use DBIx::Squirrel::Stages::Rows;

my @titles = $dbh->iterate('SELECT title, year FROM album ORDER BY year', pluck('title'))->all;
say "@titles";    # Disraeli Gears Arrival Parklife The Great Escape

my $album = $dbh->iterate('SELECT title, year FROM album WHERE id = 2', as_hash)->single;
say "$album->{title} ($album->{year})";    # Parklife (1994)
```

### Number the results, or see the row as fetched

DBIx::Squirrel::Context tells a stage which result it's making, and the
row it's making it from:

```perl
use DBIx::Squirrel::Context qw(result_number result_original);

my @chart = $dbh->iterate(
    'SELECT name, plays FROM track ORDER BY plays DESC',
    sub { $_->[0] },
    sub { result_number() . ". $_ (" . result_original()->[1] . ' plays)' },
)->all;
say $chart[0];    # 1. Dancing Queen (9101 plays)
```

### Hand out rows in batches

`batch`, from DBIx::Squirrel::Stages::Batch, passes rows on in batches,
each an array, the last, shorter one when the rows run out:

```perl
use DBIx::Squirrel::Stages::Batch;
use DBIx::Squirrel::Stages::Rows;

my $batches = $dbh->iterate('SELECT name FROM track ORDER BY id', pluck(0), batch(4));
while (my($batch) = $batches->next) {
    say scalar(@$batch), ': ', join ', ', @$batch;
}
# 4: Dancing Queen, Knowing Me, Knowing You, Girls & Boys, Parklife
# 2: Country House, Sunshine of Your Love
```

### Make one value from every row

`collect` holds the rows, and once they run out, passes on what its
block makes of them, given as its arguments, or, without a block, an
array of them:

```perl
use DBIx::Squirrel::Stages::Batch;

my $names = $dbh->iterate(
    'SELECT name FROM artist ORDER BY name',
    sub { $_->[0] },
    collect { join ', ', @_ },
)->single;
say $names;    # Abba, Blur, Cream

my $rows = $dbh->iterate('SELECT name FROM artist', collect)->single;
say scalar @$rows;    # 3
```

The block is called even when there are no rows, so an empty result
still gives a value: here, an empty string, or an empty array.

### Write a stage that keeps count, or acts at the end

`batch` and `collect` are made with `gather`, from
DBIx::Squirrel::Gather. Its block is called each time the statement
runs, so what it declares starts afresh, and it returns the stage, and
optionally a function called when the rows run out:

```perl
use DBIx::Squirrel::Gather;

# Each value, then, once they run out, how many there were
sub and_count () {
    return gather {
        my $count = 0;    # fresh on each run
        my $stage = sub ($value) { $count++; return $value };
        my $end   = sub () { "($count)" };
        return ($stage, $end);
    };
}

my @lines = $dbh->iterate('SELECT name FROM artist ORDER BY name', sub { $_->[0] }, and_count)->all;
say "@lines";    # Abba Blur Cream (3)
```

### Watch rows go by, or count them

`peek` and `count_into`, from DBIx::Squirrel::Stages::Taps, look at each
value as it goes by, and pass it on as it is. `dump_to`, on request,
writes each with Data::Dumper, to STDERR or a filehandle you give. It's
for debugging, and writes values in full, so take it out before the
code goes live:

```perl
use DBIx::Squirrel::Stages::Flow;
use DBIx::Squirrel::Stages::Taps;

my $read  = 0;
my @first = $dbh->iterate(
    'SELECT name FROM artist ORDER BY name',
    count_into(\$read),
    peek { say "read $_->[0]" },
    sub { $_->[0] },
    take(2),
)->all;
say "@first, from $read rows";
# read Abba
# read Blur
# Abba Blur, from 2 rows
```

`take` stops the iteration once it has two, so the third row is never
read.

### Reuse a pipeline's stages

Make a pipeline once, and give its stages, with `stages`, wherever
stages go: to `iterate`, `results` or another pipeline, with more
stages after them:

```perl
use DBIx::Squirrel::Pipeline;
use DBIx::Squirrel::Stages::Flow;
use DBIx::Squirrel::Stages::Rows;

my $hits = DBIx::Squirrel::Pipeline->new(
    sub { $_->[1] >= 5000 ? $_ : () },    # 5,000 plays or more
    pluck('name'),
);

my $by_plays = 'SELECT name, plays FROM track ORDER BY plays DESC';
say join ', ', $dbh->iterate($by_plays, $hits->stages)->all;
    # Dancing Queen, Sunshine of Your Love, Girls & Boys, Parklife
say join ', ', $dbh->iterate($by_plays, $hits->stages, take(2))->all;
    # Dancing Queen, Sunshine of Your Love
```

The stages run as if listed there. Give `$hits->stages`, not `$hits`:
a pipeline isn't a stage. A stage that keeps count or remembers
something should be made with `gather`, so it starts afresh in each
pipeline it's given to.

### Catch errors in a stage

A stage that catches errors itself should throw a stop on again, so the
iterator still stops:

```perl
use experimental qw(try);
use DBIx::Squirrel::Stop;

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

### See what went wrong in a stage

A stage that dies is reported at the line that asked for the result,
with the stage's number:

```perl
my $it = $dbh->iterate('SELECT name FROM artist', sub { die "no names today\n" });
eval { $it->next };
print $@;    # Pipeline stage #1 failed at ... line ...:
             #     no names today

my @after = $it->next;    # (): the iterator has ended
```

Once a stage dies, the iterator has ended: `next` returns nothing more,
and the statement is finished. `reset` runs it again from the start.
To pass over a row a stage can't handle, catch the error in the stage,
as in [Catch errors in a stage](#catch-errors-in-a-stage).

## Rows as objects

### Have a method for each column

Ask for `results` instead of `iterate`. Methods are named after the
columns, in lower case:

```perl
my $album = $dbh->results('SELECT id, Title, year FROM album WHERE id = $1', 2)->single;
say $album->title, ' ', $album->year;    # Parklife 1994
```

Rows are arrays still, so `$album->[1]` works too.

### Name a column that has no method

A column whose name can't be a method's, such as `COUNT(*)`, gets a
method if the statement gives it a name, and `get_column` reaches it
either way:

```perl
my $row = $dbh->results('SELECT COUNT(*), COUNT(*) AS albums FROM album')->single;
say $row->albums;                   # 4
say $row->get_column('COUNT(*)');   # 4
say $row->get_column(0);            # 4
```

### Give rows methods of your own

Make a subclass of DBIx::Squirrel::Result, and name it in the
`ekorn_result_class` attribute:

```perl
package My::Album {
    our @ISA = 'DBIx::Squirrel::Result';
    sub label ($self) { sprintf '%s (%d)', $self->title, $self->year }
}

my $results = $dbh->results(
    'SELECT title, year FROM album ORDER BY year',
    {ekorn_result_class => 'My::Album'},
);
while (my($album) = $results->next) {
    say $album->label;    # Disraeli Gears (1967), ...
}
```

### Transform objects with stages

Stages see the objects:

```perl
my @recent = $dbh->results(
    'SELECT title, year FROM album',
    sub { $_->year >= 1990 ? $_ : () },
    sub { $_->title },
)->all;
say "@recent";    # Parklife The Great Escape
```

## Pipelines without a database

### Run a handle through stages

`pipe` runs a database or statement handle through stages, and returns
what comes out. `tap` does the same for the side effects, and returns
the handle:

```perl
my @names = $dbh->pipe(
    sub ($dbh) { @{ $dbh->selectcol_arrayref('SELECT name FROM artist') } },
    sub { uc },
);
say "@names";    # ABBA BLUR CREAM

$dbh->tap(sub ($dbh) { say 'albums: ', $dbh->selectrow_array('SELECT COUNT(*) FROM album') })
    ->do('UPDATE album SET year = year WHERE id = 1');
```

The canned stages work here too, as the handle is just the first value:

```perl
use DBIx::Squirrel::Stages::Flow;
use DBIx::Squirrel::Stages::Taps;

my @two = $dbh->pipe(
    sub ($dbh) { @{ $dbh->selectcol_arrayref('SELECT name FROM artist ORDER BY name') } },
    take(2),
);
say "@two";    # Abba Blur

$dbh->tap(peek { say "on $_->{Driver}{Name}" })->do('UPDATE album SET year = year WHERE id = 1');
# on SQLite
```

### Run any values through stages

A pipeline is called with values, and returns what comes out of its
last stage:

```perl
use DBIx::Squirrel::Pipeline;

my $evens_squared = DBIx::Squirrel::Pipeline->new(
    sub { $_ % 2 ? () : $_ },
    sub { $_ * $_ },
);
say join ' ', $evens_squared->(1 .. 6);    # 4 16 36
```

### Let callers of your own functions add stages

A function can take stages from its caller, as `iterate` does, and run
what it returns through them, so the caller gets it ready to use.
Loading the pipeline, `gather`, `Stop` and the canned stages doesn't
load the DBI, so this works in code that has nothing to do with a
database:

```perl
use DBIx::Squirrel::Pipeline;
use DBIx::Squirrel::Stages::Rows;

# The bands, as hashes, through whatever stages the caller gives
sub bands (@stages) {
    my @bands = (
        {name => 'Abba',  formed => 1972},
        {name => 'Blur',  formed => 1988},
        {name => 'Cream', formed => 1966},
    );
    return DBIx::Squirrel::Pipeline->new(@stages)->(@bands);
}

my @older = bands(sub { $_->{formed} < 1980 ? $_ : () }, pluck('name'));
say "@older";    # Abba Cream

my @all = bands();    # without stages, as they are
say scalar @all;      # 3
```

The stages that need a statement's column names need an iterator:
`as_hash`, and `pluck` with a name for an array or a position for a
hash. `pluck` with a name for a hash, as here, doesn't. Outside an
iterator, DBIx::Squirrel::Context's functions return `undef`.

### Pull values from anything, one at a time

A pipeline's `iterator` pulls values from a source of your own, such as
a file or a paged API. Ekorn::Pipeline's how-to has the recipes, in
[Pulling values one at a time](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/HOWTO.md#pulling-values-one-at-a-time), and
more on functions that take stages, in
[Writing a function that takes stages](https://github.com/nukopian/Ekorn-Pipeline/blob/main/docs/HOWTO.md#writing-a-function-that-takes-stages).

## A function for each database and statement

DBIx::Squirrel::Sugar gives each database, and each statement, a
function of its own name.

### Name a database

Defined on `use`, the function is there as the program compiles, so it
can be called without parentheses. The database is connected to when
it's first used.

```perl
use DBIx::Squirrel::Sugar database => {
    music => ['dbi:SQLite:dbname=music.db', '', '', {RaiseError => 1}],
};

my $handle = music;                                   # the database handle
my $sth    = music 'SELECT name FROM artist WHERE id = ?', 1;
say $sth->fetchrow_arrayref->[0];                     # Abba

my @names = music 'SELECT name FROM artist', sub { $_->[0] };
say "@names";                                         # Abba Blur Cream
```

### Name a statement, with stages of its own

```perl
use DBIx::Squirrel::Sugar statement => {
    titles_by => [music => 'SELECT title FROM album WHERE artist_id = :artist ORDER BY year',
        sub { $_->[0] }],
    album     => [music => 'SELECT * FROM album WHERE id = ?'],
};

my @titles = titles_by artist => 2;
say "@titles";    # Parklife The Great Escape

my @shouted = titles_by artist => 2, sub { uc };    # more stages, for this call
say "@shouted";   # PARKLIFE THE GREAT ESCAPE

my $sth = album 1;    # no stages: the statement handle, executed
say $sth->fetchrow_hashref->{title};    # Arrival
```

### Define them as the program runs

```perl
use DBIx::Squirrel::Sugar qw(database statement);

database(archive => 'dbi:SQLite:dbname=music.db', '', '', {RaiseError => 1});
statement(artist_count => archive => 'SELECT COUNT(*) FROM artist', sub { $_->[0] });

my($n) = artist_count();
say $n;    # 3
say ref database('archive');    # DBIx::Squirrel::db
```

## Caching

### Prepare a statement once, wherever it's used

`prepare_cached` keeps the handle on the database handle, as the DBI
does. A statement written two ways gets a handle each:

```perl
my $one = $dbh->prepare_cached('SELECT :a, :b');
my $two = $dbh->prepare_cached('SELECT :b, :a');
say $one == $two ? 'shared' : 'apart';    # apart
```

A cached handle an iterator is part way through is left to it, and a
new one is made in its place:

```perl
my $sql   = 'SELECT name FROM artist ORDER BY id';
my $first = $dbh->prepare_cached($sql)->iterate(sub { $_->[0] });
my($name) = $first->next;
say $name;                               # Abba
my $second = $dbh->prepare_cached($sql)->iterate(sub { $_->[0] });
say join ' ', $second->all;             # Abba Blur Cream
say join ' ', $first->all;              # Blur Cream
```

### Share a connection

`connect_cached` hands back the same handle for the same arguments:

```perl
my $one = DBIx::Squirrel->connect_cached('dbi:SQLite:dbname=music.db', '', '', {RaiseError => 1});
my $two = DBIx::Squirrel->connect_cached('dbi:SQLite:dbname=music.db', '', '', {RaiseError => 1});
say $one == $two ? 'the same handle' : 'two handles';    # the same handle
```

## Handling errors

### Find the line that went wrong

Every error is reported at the line of your code that called
DBIx::Squirrel, the DBI's own included:

```perl
eval { $dbh->prepare('SELEC name FROM artist') };
print $@;    # DBD::SQLite::db prepare failed: near "SELEC": syntax error at ... line ...
```

So is each warning the DBI gives under `PrintError`, its default, naming
the method you called, as plain DBI does:

```perl
my $chatty = DBIx::Squirrel->connect('dbi:SQLite:dbname=music.db', {RaiseError => 0, PrintError => 1});
local $SIG{__WARN__} = sub ($warning) { print "warned: $warning" };
$chatty->selectrow_array('SELECT * FROM nowhere');
# warned: DBD::SQLite::db selectrow_array failed: no such table: nowhere at ... line ...
```

### Rely on connect and prepare croaking

`connect` and `prepare` croak whatever `RaiseError` says, so they need
no `or die`. Without `RaiseError`, the other methods return what the
DBI's return:

```perl
my $quiet = DBIx::Squirrel->connect('dbi:SQLite:dbname=music.db', {RaiseError => 0, PrintError => 0});

my $row = $quiet->selectrow_arrayref('SELEC 1');
say defined $row ? 'a row' : 'undef, as from the DBI';    # undef, as from the DBI

eval { $quiet->prepare('SELEC 1') };
say $@ ? 'prepare croaked' : 'prepare returned';           # prepare croaked
```

### Mismatched bind values

Binding croaks, at your line, when the values don't fit the
placeholders:

```perl
eval { $dbh->prepare('SELECT :id, :name')->execute(id => 1) };
print $@;    # Expected a value for each placeholder (none for name) at ... line ...
```

Executing without any values croaks too, unless each placeholder has a
value bound already, where the DBI would quietly read it as `NULL`:

```perl
my $sth = $dbh->prepare('SELECT name FROM artist WHERE id = :id');
eval { $sth->execute };
print $@;    # Expected a value for each placeholder (none for id) at ... line ...

$sth->bind_param(id => 3);
$sth->execute;
say $sth->fetchrow_arrayref->[0];    # Cream

eval { $dbh->selectrow_array('SELECT name FROM artist WHERE id = $1') };
print $@;    # Expected a value for each placeholder (none for 1) at ... line ...
```
