<div align="center">
    <img src="./resources/images/ekorn.png" width="128">
    <h1>
        DBIx-Squirrel<br>
        <a href="https://metacpan.org/dist/DBIx-Squirrel"><img src="https://img.shields.io/cpan/v/DBIx-Squirrel"></a>
        <img src="https://img.shields.io/github/release-date/nukopian/DBIx-Squirrel">
        <img src="https://img.shields.io/cpan/l/DBIx-Squirrel">
    </h1>
    <p>••• <a href="http://fast-matrix.cpantesters.org/?dist=DBIx-Squirrel%201.4.2">Current release status on the CPAN Testers Matrix</a> •••</p>
    <p><em>The little Perl DBI extension that makes working with databases
    a lot easier.</em><p>
</div>

## Introduction

Using DBIx-Squirrel is just like using the DBI, but with upgrades.

You can quickly get to a sweet-spot, somewhere between classic DBI and
and DBIx-Class programming, while being burdened with few, if any,
cognitive demands, provided that you have some familiarity with
either (or both) of the alternatives.

Just as with the DBI, all database queries are crafted with SQL,
keeping you close to the data. Through iterators and transformations,
DBIx-Squirrel offers a clean and elegant paradigm for efficiently
processing results. Even DBIx-Squirrel iterators share interface
commonalities with those of DBIx-Class result-sets, further
flattening the learning curve.

Pretty much everything that can be done with the DBI can be done with
DBIx-Squirrel, if need be, the same way. DBIx-Squirrel enhancements
are progressive in nature, working in harmony with features provided
by its venerable ancestor. You won't be forced into a radically
different mindset just to accomplish simple tasks.

While this package is not going to set the world on fire, it will help
those with a need to quickly hack-together data-processing scripts, and
to do so with absolute ease.

#### Examples

To whet the appetite, let's take a look at some example code.

The DBIx-Squirrel distribution ships with a SQLite database (`t/data/chinook.db`),
which is used for testing. We will use the same database for the examples.

##### 1. `examples/04.pl`

```perl
use DBIx::Squirrel;

$dbh = DBIx::Squirrel->connect('dbi:SQLite:dbname=t/data/chinook.db', '', '');

$artists = $dbh->results(
    'SELECT Name FROM artists ORDER BY Name' => sub {$_->Name}
);

print "$_\n" while $artists->next();

$dbh->disconnect();
```

To run, change to the directory in which you untarred the distribution,
and type:

```shell
perl -Ilib examples/04.pl
```

Summary:

- connect to the database;
- print the names of all artists in alphabetic order;
- disconnect from the database.

Clearly, the tasks of connecting to and disconnecting from the database
are accomplished here as they would be with the DBI.

The `$dbh->results(...)` call returns a result set iterator instance,
and this is being assigned to `$artists`. The iterator is based upon
a standard SQL query, which also takes care of ordering the results.

The `=> sub {$_->Name}` following the SQL query is a single-stage
transformation returning the result's `Name` attribute. Absent any
transformations, a row object would be returned.

*The intended purpose of a transformation is to change the shape of
data, ensuring that only the information required by the caller is
returned. The caller retains the flexibility to tailor results to
their specific requirements, removing the need for the function's 
author to anticipate and bake-in those requirements.*

*The manner in which transformations are declared produces a visibly
clear and logical association between them and the SQL query from which
results will emanate.*

Next we print out the results, one at a time. The `while $artists->next()`
postfix while-loop ensures that we do this only while the iterator
produces a "truthy" result. That's good enough here, *but there are
better ways to do it.*

This approach is succinct, clean and elegant, and there is no clutter
littering the calling context&mdash;*no temporary state, and definitely
no untangling of the results' innards just to get at the information
we wanted.*

##### 2. `examples/05.pl`

```perl
use DBIx::Squirrel;

$dbh = DBIx::Squirrel->connect('dbi:SQLite:dbname=./t/data/chinook.db', '', '');

$artists = $dbh->results(
    'SELECT * FROM artists ORDER BY ArtistId' => sub {
        my($result) = @_;
        printf STDERR "# %3d. %s\n", $result->ArtistId, $result->Name
            if !!$ENV{DEBUG};
        $result;
    } => sub {
        return $_->Name;
    }
);

@artists = $artists->all();

$dbh->disconnect();
```

To run, change to the directory in which you untarred the distribution,
and type:

```shell
perl -Ilib examples/05.pl
```

Summary:

- connect to the database;
- gather the names of all artists in alphabetic order;
- disconnect from the database.

Not too dissimilar from the previous example. This time, we throw caution
to the wind and gather *all* of the artists' names into the `@artists`
array.

Ordinarily, that would be the end of it. On this occasion, however,
we require some assurance that things are working as intended. To this
end, an extra processing stage has been injected at the start of the
transformation, and its purpose is to output the needed debug information
if the `DEBUG` environment variable contains a truthy value. The result
is passed unchanged along to the next stage of the transformation.

From this example, we can intuit the following:

- the result in its current form enters each stage of transformation as
`$_`, but also as the first element of `@_` for when we need something
less ephemeral;
- the result, which may or may not have changed, is passed along to the
next stage of the transformation as the final evaluated expression, or
via an explicit `return` statement;
- the result of the final stage of a transformation is what the caller
gets.

A transformation is presented as a *contiguous* chain of CODEREFs at the
end of the iterator's argument list. You can separate each stage with a
comma (`,`), though the long-comma (`=>`) is more expressive, since it
indicates the result's direction of travel through a transformation.
