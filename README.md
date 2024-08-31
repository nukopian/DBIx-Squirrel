<div align="center">
    <img src="./resources/images/ekorn.png" width="128">
    <h1>DBIx-Squirrel</h1>
    <img src="https://img.shields.io/cpan/v/DBIx-Squirrel">
    <img src="https://img.shields.io/github/release-date/nukopian/DBIx-Squirrel">
    <img src="https://img.shields.io/cpan/l/DBIx-Squirrel">
    <p>
        <em>A little Perl DBI extension that makes working with databases a lot easier.</em>
    </p>
</div>

## Introduction

Using DBIx-Squirrel is just like using the DBI, but with a few very nice
upgrades. It will get you to a sweet-spot between classic DBI and
programming with DBIx-Class, with practically no learning curve
whatsoever.

As with the DBI, database queries are crafted with SQL, keeping you close
to the data, while processing result-sets can be done cleanly and efficiently
with iterators and simple yet powerful transformations. 

Pretty much everything you could do with the DBI can be done in exactly
the same fashion with DBIx-Squirrel. Its enhancements are progressive
in nature, and you are not forced to use them to get things done.

While this package won't set the world on fire, it will help those who
need to hack together data-processing scripts quickly, and with ease.

### An example

```perl
use DBIx::Squirrel;

$dbh = DBIx::Squirrel->connect("dbi:SQLite:dbname=./t/data/chinook.db", "", "");

$artist_names = $dbh->results(
    "SELECT Name FROM artists ORDER BY Name" => sub {$_->Name}
);

print "$_\n" while $artist_names->next();

$dbh->disconnect();
```
