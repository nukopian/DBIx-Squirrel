use v5.36;

package DBIx::Squirrel::Placeholders;

use Exporter qw(import);

use namespace::clean -except => 'import';

our @EXPORT_OK = qw(
    study_sql
    trim_sql
);

# Remove the blank space from around a statement; return what's left, or
# an empty string if it was all blank.
sub trim_sql ($statement) {
    return ($statement // '') =~ s/ \A \s+ | \s+ \z //gxr;
}

# Study a statement, written for the DBI driver named; return a map of its
# placeholders' positions, from 1, to their names, the statement with each
# placeholder rewritten as "?", and the statement as trimmed. Return
# nothing if the statement is blank.
sub study_sql ($statement, $driver = undef) {
    my $trimmed = trim_sql($statement);
    return unless length $trimmed;

    # What isn't SQL code, and is stepped over unchanged: quoted strings and
    # identifiers, comments, PostgreSQL's dollar-quoted bodies, and a
    # backslash before "?", ":" or "$", which DBD::Pg takes to mean the
    # character isn't a placeholder, and removes.
    state $STRING   = qr( ' (?: [^'] | '' )* ' )x;
    state $E_STRING = qr( (?<! \w ) [Ee] ' (?: [^'\\] | \\. | '' )* ' )x;
    state $IDENT    = qr( " (?: [^"] | "" )* " | ` [^`]* ` )x;
    state $COMMENT  = qr( -- [^\n]* | /\* .*? \*/ )xs;
    state $DOLLARS  = qr( \$ (?<tag> (?: [A-Za-z_]\w* )? ) \$ .*? \$ \k<tag> \$ )xs;
    state $ESCAPED  = qr( \\ [?:\$] )x;
    state $NOT_SQL
        = qr( $E_STRING | $STRING | $IDENT | $COMMENT | $DOLLARS | $ESCAPED )x;

    # The same for MySQL and MariaDB, where a backslash escapes a character
    # in a string, "..." is a string, not an identifier, and "#" starts a
    # comment.
    state $MYSQL_STRING
        = qr( ' (?: [^'\\] | \\. | '' )* ' | " (?: [^"\\] | \\. | "" )* " )x;
    state $MYSQL_NOT_SQL = qr( $MYSQL_STRING | ` [^`]* ` | $COMMENT | \# [^\n]* )x;
    state %NOT_SQL_FOR   = (mysql => $MYSQL_NOT_SQL, MariaDB => $MYSQL_NOT_SQL);

    # A placeholder: "?", "?" and a position, or ":" or "$" and a position or
    # a name; not after a colon, as in a cast, or inside an identifier.
    state $PLACEHOLDER = qr( (?<! [:\w\$] ) (?: \? \d* | [:\$] \w+ ) )x;

    my $not_sql = $NOT_SQL_FOR{$driver // ''} // $NOT_SQL;
    my @placeholders;
    my $normalised = $trimmed =~ s(
        (?<not_sql> $not_sql ) | (?<placeholder> $PLACEHOLDER )
    )(
        if (exists $+{not_sql}) {
            $+{not_sql};
        }
        else {
            push @placeholders, $+{placeholder};
            '?';
        }
    )gerx;

    my %positions = map { ($_ + 1 => $placeholders[$_]) } keys @placeholders;
    return \%positions, $normalised, $trimmed;
}

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel::Placeholders - find the placeholders in a statement

=head1 SYNOPSIS

    use DBIx::Squirrel::Placeholders qw(study_sql trim_sql);

    my($positions, $normalised, $trimmed)
        = study_sql('SELECT * FROM artist WHERE id = :id');
    # ({1 => ':id'}, 'SELECT * FROM artist WHERE id = ?', ...)

=head1 DESCRIPTION

The functions L<DBIx::Squirrel::db>'s C<prepare> uses to find the
placeholders in a statement and rewrite them as C<?> for the DBI.
Neither is exported by default.

=head1 FUNCTIONS

=head2 study_sql

    ($positions, $normalised, $trimmed) = study_sql($statement);
    ($positions, $normalised, $trimmed) = study_sql($statement, $driver);

Returns a hash reference mapping each placeholder's position, from 1, to
the placeholder as written (C<?>, C<?1>, C<:1>, C<$1> or C<:name>); the
statement with each placeholder rewritten as C<?>; and the statement as
L</trim_sql> returns it. Returns nothing if the statement is blank.

Placeholders are looked for only in the SQL itself, not in quoted
strings or identifiers, comments or PostgreSQL's dollar-quoted bodies,
and not in casts, such as C<x::int>, or identifiers containing C<$>,
such as C<v$session>. A C<?>, C<:> or C<$> with a backslash before it
isn't a placeholder either, and both are left as they are, for
L<DBD::Pg>, which removes the backslash.

C<$driver> is the name of the DBI driver the statement is for, as in
C<< $dbh->{Driver}{Name} >>. For C<mysql> and C<MariaDB>, a backslash
escapes a character in a string, C<"..."> is a string, and C<#> starts a
comment. For any other driver, or none, a backslash is an ordinary
character in a string, except in PostgreSQL's C<E'...'> strings.

=head2 trim_sql

    $trimmed = trim_sql($statement);

Returns the statement without the blank space around it, or an empty
string if it was all blank or C<undef>. Comments are kept.

=head1 SEE ALSO

L<DBIx::Squirrel::db>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
