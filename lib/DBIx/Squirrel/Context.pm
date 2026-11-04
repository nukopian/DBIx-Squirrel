use v5.36;

package DBIx::Squirrel::Context;

use Exporter qw(import);

our @EXPORT_OK = qw(iterator result_number result_original);

# Report a stage's errors at the line that called DBIx::Squirrel, past
# the iterator running the stages.
our @CARP_NOT = qw(DBIx::Squirrel::Iterator DBIx::Squirrel::Pipeline);

# What a stage can ask about the result it's making, set by the iterator
# running it.
my %context;

# The iterator running the stage.
sub iterator (@) {
    return $context{iterator};
}

# The number of the result being made, from 1.
sub result_number (@) {
    return $context{number};
}

# The row the result is being made from, as it was fetched.
sub result_original (@) {
    return $context{original};
}

# For DBIx::Squirrel's iterators: run code with the context given, and
# return what it returns.
sub within ($values, $code) {
    local @context{keys %$values} = values %$values;
    return $code->();
}

# For DBIx::Squirrel's iterators: change the original row while code run
# by within runs.
sub set_original ($row) {
    $context{original} = $row;
    return;
}

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel::Context - what a stage can ask about the result it's making

=head1 SYNOPSIS

    use DBIx::Squirrel::Context qw(result_number result_original);

    my $it = $dbh->iterate(
        'SELECT name FROM artist ORDER BY name',
        sub ($row) { "@{[ result_number ]}. $row->[0]" },
    );

=head1 DESCRIPTION

Inside a stage run by a L<DBIx::Squirrel::Iterator>, these functions
return what the stage might want to know about the result it's making,
which it can't work out from the value it's given. Outside a stage,
they return C<undef>. None is exported by default.

=head1 FUNCTIONS

=head2 iterator

The iterator running the stage. Its C<sth> is the statement handle,
and the statement handle's C<Database>, the database handle.

=head2 result_number

The number of the result being made, from 1. It counts results, not
rows: while a stage drops rows, the number stays the same, and each
value a stage returns in place of one row is a result of its own.

=head2 result_original

The row the result is being made from, as it was fetched, before any
stage changed it.

=head2 within, set_original

For DBIx::Squirrel's iterators, which set the context while their
stages run; not for use elsewhere.

=head1 SEE ALSO

L<DBIx::Squirrel::Iterator>, L<DBIx::Squirrel::Pipeline>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
