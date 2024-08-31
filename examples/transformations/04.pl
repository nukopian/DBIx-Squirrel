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
