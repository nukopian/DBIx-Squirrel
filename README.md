<div id="dbix-squirrel-top" align="center">
    <a href="https://metacpan.org/dist/DBIx-Squirrel" title="Go to the distribution's page on MetaCPAN"><img src="./resources/images/ekorn.png" width="128"></a>
    <h1>
        DBIx-Squirrel<br>
        <a href="https://metacpan.org/dist/DBIx-Squirrel" title="Go to the distribution's page on MetaCPAN"><img src="https://img.shields.io/cpan/v/DBIx-Squirrel"></a>
        <a href="https://github.com/nukopian/DBIx-Squirrel/releases/tag/1.5.2"><img src="https://img.shields.io/github/v/release/nukopian/DBIx-Squirrel?label=github&color=tan"></a>
        <a href="https://github.com/nukopian/DBIx-Squirrel/releases/tag/1.5.2"><img src="https://img.shields.io/github/release-date/nukopian/DBIx-Squirrel?color=tan"></a>
        <img src="https://img.shields.io/cpan/l/DBIx-Squirrel">
    </h1>
    <p><em>The little Perl DBI extension that makes working with databases
    a lot easier.</em><p>
    <p>• <a href="http://fast-matrix.cpantesters.org/?dist=DBIx-Squirrel%201.4.2">Current release status on the CPAN Testers Matrix</a> •</p>
</div>

## Table of Contents

- [Introduction](#introduction)
- [Installation](#installation)
- [POD page](docs/POD/)


## Introduction

Using DBIx-Squirrel is just like using the DBI, but with upgrades.
Those with some experience of classic DBI and DBIx-Class programming
can quickly get to a sweet-spot somewhere between both.

Just as with the DBI, all database queries are crafted with SQL,
keeping you close to the data. With its built-in support for named,
positional and legacy parameter placeholders, DBIx-Squirrel makes
the task of crafting that SQL a lot less bothersome, while its
iterators and transformations offer a clean and elegant way to
process results.

Most comforting of all, everything that could be done with the DBI
can still be done using DBIx-Squirrel. Enhancements are subtle and
progressive in nature, and intended to work in harmony features
provided by its venerable ancestor.

While this package is not going to set the world on fire, it will
help those with a need to quickly hack-together data-processing
scripts, and to do so with absolute ease.

#### Examples

To whet the appetite, let's take a look at some example code.

The DBIx-Squirrel distribution ships with a SQLite database
(`t/data/chinook.db`), which is used for testing. We will use
the same database for the examples.

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
transformation returning the result's `Name` attribute. This type of
iterator allows access to attribute values using accessors. Without the
transformation, a row object would be returned to the caller.

The intended purpose of a transformation is to change the shape of
data, ensuring that only the information required by the caller is
returned. The caller retains the flexibility to tailor results to
their specific requirements, removing the need for the function's 
author to anticipate and bake-in those requirements.

The manner in which transformations are declared produces a visibly
clear and logical association between them and the SQL query from which
results will emanate.

Next we print out the results, one at a time. The `while $artists->next()`
postfix while-loop ensures that we do this only while the iterator
produces a "truthy" result. That's good enough here, *but there are
better ways to do it.*

This approach is succinct, clean and elegant, and there is no clutter
littering the calling context&mdash;*no temporary state, and definitely
no untangling the innards of results just to get at the information
we wanted.*

<div align="right">Go to: <a href="#dbix-squirrel-top">Top</a></div>

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

Not too dissimilar from the previous example. This time, we confessf caution
to the wind and gather *all* of the artists' names into the `@artists`
array.

Ordinarily, that would be the end of it. On this occasion, however,
we require some assurance that things are working as intended. To this
end, an extra processing stage has been injected at the start of the
transformation, and its purpose is to output the needed debug information
if the `DEBUG` environment variable contains a truthy value. The result
is passed unchanged along to the next stage of the transformation.

A transformation is presented as a *contiguous* chain of one or
more CODEREFs at the end of the iterator's argument list. Stages
are separated other arguments (and each other) using the comma
(`,`). Separation using the long-comma (`=>`) is also possible, provided
the token to its left is not a bare word; it also serves as a metaphor
for the result's direction of travel through the transformation
process.

From these examples, we can intuit the following about transformations:

- the result (in its current form) enters a transformation stage as `$_`,
and as the first element of the `@_` array, for when we need something
less ephemeral;
- the result (which may, or may not, have changed), is passed to the
next stage of the transformation, or to the caller, as the final
evaluated expression, or using an explicit `return` statement.

<div align="right">Go to: <a href="#dbix-squirrel-top">Top</a></div>

## Installation

### Install with `App::cpanminus`

#### Automated installation

```shell
cpanm DBIx::Squirrel
```

#### Manual installation

If you prefer to install manually, or you would like to try out any of the
example code in a sub-shell:

```shell
cpanm --look DBIx::Squirrel
perl Makefile.PL
make && make test && make install
```

#### Uninstall with `App::cpanminus`

In the unfortunate event that things don't work out...
```shell
cpanm --uninstall DBIx::Squirrel
```

<div align="right">Go to: <a href="#dbix-squirrel-top">Top</a></div>
