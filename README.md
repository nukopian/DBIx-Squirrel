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
upgrades. This DBI extension will you to a sweet-spot, somewhere between
classic DBI and DBIx-Class, with practically no learning curve.

As with the DBI, database queries are crafted with SQL, keeping you close
to the data, while results can be processed cleanly and efficiently with
DBIx-Squirrel's simple yet powerful transformation pipelines.

Pretty much everything you could do with the DBI can be done the exact
same way with this package. DBIx-Squirrel's enhancements are progressive
in nature and you aren't forced to use them to get things done.

While this package won't set the world on fire, it will help those who
need to hack together data-processing scripts quickly and with ease.

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
