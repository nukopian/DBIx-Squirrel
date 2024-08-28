use DBIx::Squirrel database_entities => [qw/db get_artists/];
use DBIx::Squirrel::Iterator qw/dbh itor offset result/;

db do {
    DBIx::Squirrel->connect(
        "dbi:SQLite:dbname=./t/data/chinook.db",
        "",
        "",
        {   PrintError     => !!0,
            RaiseError     => !!1,
            sqlite_unicode => !!1,
        },
    );
};

get_artists do {
    db->results(
        "SELECT ArtistId, Name FROM artists LIMIT 100" => sub {
            my($artist) = @_;
            printf "---- %s\n", dbh;
            printf "%4d Name: %s\n", offset, $artist->Name;
            return $artist;
        } => sub {$_->ArtistId}
    );
};

get_artists->all;

db->disconnect();
