use v5.36;

package DBIx::Squirrel::Results;

use Carp qw(croak);

use DBIx::Squirrel::Iterator qw();
use DBIx::Squirrel::Result   qw();

use namespace::clean;

our @ISA = ('DBIx::Squirrel::Iterator');

# Croak at the line that called DBIx::Squirrel, past its own code and the
# DBI's.
our @CARP_NOT = qw(
    DBIx::Squirrel         DBIx::Squirrel::db       DBIx::Squirrel::st
    DBIx::Squirrel::Errors DBIx::Squirrel::Pipeline DBIx::Squirrel::Context
    DBIx::Squirrel::Iterator
);

# Fetch rows as arrays, whatever ekorn_slice says, as their classes find
# columns by position.
sub _slice ($self) {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    return [];
}


# Bless a row into the class for the statement's columns. The iterator
# calls it for each row it fetches.
sub _row ($self, $row) {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    $self->{row_class} //= _base_class($self)->class_for($self->sth->{NAME_lc});
    return bless $row, $self->{row_class};
}


# Return the base class of the rows' class: the ekorn_result_class
# attribute, or DBIx::Squirrel::Result.
sub _base_class ($self) {
    my $base = $self->sth->{private_ekorn}{Options}{ekorn_result_class}
        // 'DBIx::Squirrel::Result';
    croak
        "Expected ekorn_result_class to be a subclass of DBIx::Squirrel::Result ($base)"
        unless $base->isa('DBIx::Squirrel::Result');
    return $base;
}

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel::Results - an iterator handing out rows as objects

=head1 SYNOPSIS

    my $results = $dbh->results(
        'SELECT id, Name FROM artist WHERE id <= ?', 10,
        sub ($artist) { $artist->name },
    );
    while (my($name) = $results->next) {
        say $name;
    }

    my $artist = $dbh->results('SELECT * FROM artist WHERE id = ?', 1)->single;
    say $artist->name;

=head1 DESCRIPTION

A result set is a L<DBIx::Squirrel::Iterator> whose rows are objects:
each row is fetched as an array and blessed into a class with a method
for each column, named in lower case, before the stages see it.
L<DBIx::Squirrel::Result> says how the classes are made, and how to give
rows methods of their own with the C<ekorn_result_class> attribute, on
C<connect> or C<prepare>.

Rows are always arrays: the C<ekorn_slice> attribute doesn't apply.

A result set is made by L<DBIx::Squirrel::db/results> or
L<DBIx::Squirrel::st/results>, and has the iterator's methods, and no
others. A row needs nothing from its result set, and can be kept after
it's gone.

=head1 DIAGNOSTICS

=over

=item Expected ekorn_result_class to be a subclass of DBIx::Squirrel::Result (%s)

The C<ekorn_result_class> attribute named a class that isn't one.

=back

=head1 SEE ALSO

L<DBIx::Squirrel::Iterator>, L<DBIx::Squirrel::Result>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
