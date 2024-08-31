<div align="center">
    <img src="./resources/images/ekorn.png" width="128">
    <h1>
        DBIx-Squirrel<br>
        <img src="https://img.shields.io/cpan/v/DBIx-Squirrel">
        <img src="https://img.shields.io/github/release-date/nukopian/DBIx-Squirrel">
        <img src="https://img.shields.io/cpan/l/DBIx-Squirrel">
    </h1>
    <p><strong>A little Perl DBI extension that makes working with databases a lot easier.</strong></p>
</div>

## Introduction

Using DBIx-Squirrel is just like using the DBI, but with a few very nice
upgrades. It will get you to a sweet-spot between classic DBI and
programming with DBIx-Class, with practically no learning curve
whatsoever.

As with the DBI, database queries are crafted with SQL, keeping you close
to the data, while processing result-sets can be done cleanly and efficiently
with DBIx-Squirrel's iterators and transformations. 

Pretty much everything you could do with the DBI can be done in exactly
the same fashion with DBIx-Squirrel. Its enhancements are progressive
in nature, and you are not forced to use them to get things done.

While this package won't set the world on fire, it will help those who
need to hack together data-processing scripts quickly, and with ease.

**Example 1**

We will print all artist names, sorted alphabetically by name. As we iterate over the results, each result is transformed into shape we want, namely a string containing the artist's name.

It's elegant and clean. We aren't getting an artist object back and then having to ferret about for the name. We get back what we need, and only what we need.

```perl
use DBIx::Squirrel;

$dbh = DBIx::Squirrel->connect('dbi:SQLite:dbname=./t/data/chinook.db', '', '');

$artist_names = $dbh->results(
    'SELECT Name FROM artists ORDER BY Name' => sub {$_->Name}
);

print "$_\n" while defined($artist_names->next());

$dbh->disconnect();
```

**Example 2**

Here, we just want the artist names, sorted alphabetically and stored in array. Just to ensure that we're getting what we expect, we insert a new transformation step, before the final step, to print out the artist id and name.

Again, simple and elegant. All of the processing is logically kept with the query, while we get back only what we need. Our calling scope isn't littered with the detritus of temporary state.

```perl
use DBIx::Squirrel;

$dbh = DBIx::Squirrel->connect('dbi:SQLite:dbname=./t/data/chinook.db', '', '');

$artist_names = $dbh->results(
    'SELECT * FROM artists ORDER BY ArtistId' => sub {
        my $artist = $_;
        print $artist->ArtistId, '. ', $artist->Name, "\n";
        $artist;
    } => sub {
        $_->Name;
    }
);

@artist_names = $artist_names->all();

$dbh->disconnect();
```