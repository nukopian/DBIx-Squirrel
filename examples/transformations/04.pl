use DBIx::Squirrel;

$dbh = DBIx::Squirrel->connect("dbi:SQLite:dbname=./t/data/chinook.db", "", "");

$artist_names = $dbh->results(
    "SELECT Name FROM artists ORDER BY Name" => sub {
        $_->Name;
    }
);

print "$_\n" while $artist_names->next();

$dbh->disconnect();
