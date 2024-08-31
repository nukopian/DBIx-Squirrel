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
upgrades. It gets you to a sweet spot somewhere between classic DBI and
DBIx-Class with minimal, if any, learning curve.

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
