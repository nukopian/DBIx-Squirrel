<div align="center">
    <img src="./resources/images/ekorn.png" width="128">
    <h1>DBIx-Squirrel</h1>
    <img src="https://img.shields.io/cpan/v/DBIx-Squirrel">
    <img src="https://img.shields.io/github/release-date/nukopian/DBIx-Squirrel">
    <img src="https://img.shields.io/cpan/l/DBIx-Squirrel">
    <p>
        <em>A little Perl DBI extension that makes database work a lot simpler.</em>
    </p>
</div>

Using DBIx-Squirrel is just like using the DBI, but with a few very nice
upgrades. This DBU extension gets you to a sweet spot somewhere between
classic DBI and DBIx-Class with practically no learning curve.

As with the DBI, database queries are crafted with SQL, keeping you close
to the data, while results may be processed cleanly and efficiently with
DBIx-Squirrel's simple yet powerful transformation pipelines.

This package won't set the world on fire, but it is aimed at those who need
to hack together data-processing scripts in a hurry and with ease.

```perl
use DBIx::Squirrel;

$dbh = DBIx::Squirrel->connect("dbi:SQLite:dbname=./t/data/chinook.db", "", "");

$artist_names = $dbh->results(
    "SELECT Name FROM artists ORDER BY Name" => sub {
        $_->Name;
    }
);

print "$_\n" while $artist_names->next();

$dbh->disconnect();
```
