[![Actions Status](https://github.com/nukopian/DBIx-Squirrel-2/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/nukopian/DBIx-Squirrel-2/actions?workflow=test)
# DBIx-Squirrel

DBI, minus the boilerplate, plus a pipeline.

**In development.** This is the successor to DBIx-Squirrel 1.x, being
rewritten in modern Perl (5.36 or later). Nothing here is released yet.
The version on CPAN, 1.6.5, lives in the archived
[DBIx-Squirrel-1](https://github.com/nukopian/DBIx-Squirrel-1) repository.

DBIx-Squirrel keeps you writing SQL, as the DBI does, and takes away the
friction around it: placeholders in whatever style you like, iterators
over results, and a pipeline of transformations declared beside the
query.

## Synopsis

What works so far, from [DBIx::Squirrel](https://metacpan.org/pod/DBIx%3A%3ASquirrel)'s own documentation:

    use DBIx::Squirrel;

    my $dbh = DBIx::Squirrel->connect($data_source, $username, $password, \%attr);

    # Placeholders in the style you like: ?, ?1, :1, $1 or :name
    my $sth = $dbh->prepare('SELECT * FROM artist WHERE id = :id OR name = :name');

    # Named placeholders bound by name, as pairs or in a hash reference
    $sth->execute(id => 1, name => 'AC/DC');

    # A numbered placeholder takes one value, wherever it appears
    my $row = $dbh->selectrow_hashref(
        'SELECT * FROM artist WHERE id = $1 OR parent_id = $1', undef, 2,
    );

    # A new connection with the same parameters as an existing one
    my $other = DBIx::Squirrel->connect($dbh, \%attr);

    # Run the database handle through a pipeline of stages
    my @results = $dbh->pipe(
        sub ($dbh)   { ... },
        sub ($value) { ... },
    );

    # The same, as a branch off to the side: get the handle back
    $dbh = $dbh->tap(
        sub ($dbh)   { ... },
        sub ($value) { ... },
    );

The repository is called DBIx-Squirrel-2 while it's in development. At
release it takes the original name, DBIx-Squirrel.

## Licence

Copyright (c) 2024 by Iain Campbell. This is free software; you can
redistribute it and/or modify it under the same terms as the Perl 5
programming language system itself. See the file `LICENSE`.

## Acknowledgements

Written by Iain Campbell, with Claude, Anthropic's AI model, which
reviews the code, writes parts of it where Iain asks, often from his
code for version 1, and helps with the Git Ops, the repository's setup,
and the tests and documentation.
