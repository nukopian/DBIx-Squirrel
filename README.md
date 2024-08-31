<div align="center">
    <img src="./resources/images/ekorn.png" width="128">
    <h1>DBIx-Squirrel</h1>
    <img src="https://img.shields.io/cpan/v/DBIx-Squirrel">
    <img src="https://img.shields.io/github/release-date/nukopian/DBIx-Squirrel">
    <img src="https://img.shields.io/cpan/l/DBIx-Squirrel">
    <p>
        <em>The little Perl DBI extension that makes database work a lot simpler.</em>
    </p>
</div>

    use DBIx::Squirrel;

    $dbh = DBIx::Squirrel->connect("dbi:SQLite:dbname=./t/data/chinook.db", "", "");

    $artist_names = $dbh->results(
        "SELECT Name FROM artists ORDER BY Name" => sub {
            $_->Name;
        }
    );

    print "$_\n" while $artist_names->next();

    $dbh->disconnect();
