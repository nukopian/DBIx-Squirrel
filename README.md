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

A taste of what works so far; [DBIx::Squirrel](https://metacpan.org/pod/DBIx%3A%3ASquirrel)'s own documentation has
more:

    use DBIx::Squirrel;

    my $dbh = DBIx::Squirrel->connect($data_source, $username, $password);

    # Placeholders in the style you like: ?, ?1, :1, $1 or :name
    my $sth = $dbh->prepare('SELECT * FROM artist WHERE id = :id');
    $sth->execute(id => 1);

    # Iterate over the results, each run through a pipeline of stages
    my $names = $dbh->iterate(
        'SELECT name FROM artist WHERE name LIKE ?', 'A%',
        sub ($row) { $row->[0] },
    );
    while (my($name) = $names->next) {
        say $name;
    }

    # Or have each row as an object, with a method for each column
    say $dbh->results('SELECT * FROM artist WHERE id = $1', 1)->single->name;

`docs/REFERENCE.md` describes every feature in detail, with examples.

The repository is called DBIx-Squirrel-2 while it's in development. At
release it takes the original name, DBIx-Squirrel.

## Licence

Copyright (c) 2024-2026 by Iain Campbell. This is free software; you can
redistribute it and/or modify it under the same terms as the Perl 5
programming language system itself. See the file `LICENSE`.

## Acknowledgements

Written by Iain Campbell, with Claude, Anthropic's AI model, which
reviews the code, writes parts of it where Iain asks, often from his
code for version 1, and helps with the Git Ops, the repository's setup,
and the tests and documentation.
