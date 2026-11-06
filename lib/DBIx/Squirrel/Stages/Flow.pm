use v5.36;

package DBIx::Squirrel::Stages::Flow;

use Exporter  qw(import);
use Ref::Util qw(is_coderef);

use DBIx::Squirrel::Errors qw(croakf);
use DBIx::Squirrel::Gather qw(gather);
use DBIx::Squirrel::Stop   qw();

use namespace::clean -except => 'import';

our @EXPORT = qw(take drop);    ## no critic (Modules::ProhibitAutomaticExportation)

our @EXPORT_OK   = (@EXPORT, qw(take_while drop_while));
our %EXPORT_TAGS = (all => \@EXPORT_OK);

# Croak at the line that called DBIx::Squirrel.
our @CARP_NOT = @DBIx::Squirrel::Errors::INTERNAL;

# Return a stage passing on the first $count values, then stopping the
# pipeline, so nothing after them is fetched.
sub take ($count) {
    _check_count($count);
    return gather {
        my $taken = 0;
        return sub ($value) {
            DBIx::Squirrel::Stop->throw if $taken >= $count;
            return ++$taken < $count ? $value : DBIx::Squirrel::Stop->throw($value);
        };
    };
}

# Return a stage dropping the first $count values, and passing on the
# rest.
sub drop ($count) {
    _check_count($count);
    return gather {
        my $dropped = 0;
        return sub ($value) {
            return $value if $dropped >= $count;
            $dropped++;
            return;
        };
    };
}

# Return a stage passing on values while the test given is true of them,
# and stopping the pipeline at the first it's false of.
sub take_while : prototype(&) ($test) {
    croakf 'Expected a code reference' unless is_coderef($test);
    return sub ($value) {
        return $value if $test->($value);
        DBIx::Squirrel::Stop->throw;
    };
}

# Return a stage dropping values while the test given is true of them,
# and passing on the rest, from the first it's false of.
sub drop_while : prototype(&) ($test) {
    croakf 'Expected a code reference' unless is_coderef($test);
    return gather {
        my $dropping = 1;
        return sub ($value) {
            $dropping &&= !!$test->($value);
            return $dropping ? () : $value;
        };
    };
}


sub _check_count ($count) {
    croakf 'Expected a count of 0 or more'
        unless defined $count && $count =~ m( \A \d+ \z )x;
    return;
}

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel::Stages::Flow - stages taking or dropping values: take, drop, take_while and drop_while

=head1 SYNOPSIS

    use DBIx::Squirrel::Stages::Flow;    # take and drop

    # The third page of ten
    my @page = $dbh->iterate(
        'SELECT name FROM artist ORDER BY name',
        drop(20), take(10),
    )->all;

    use DBIx::Squirrel::Stages::Flow qw(:DEFAULT take_while drop_while);

    # The tracks played more than 5000 times, most played first
    my @hits = $dbh->iterate(
        'SELECT name, plays FROM track ORDER BY plays DESC',
        take_while { $_->[1] > 5000 },
    )->all;

=head1 DESCRIPTION

Stages that decide which values go on, by their place or by a test,
whatever the values are. Each function returns a stage, and checks
what it's given when it's called, not on each value. Those that count
are made with L<DBIx::Squirrel::Gather>, so they start afresh on each
run: each execution of an iterator, including after C<reset>, and each
call of a Sugar statement.

C<take> and C<take_while> end the pipeline with
L<DBIx::Squirrel::Stop> once they have passed on all they will, so an
iterator fetches no more rows, and finishes its statement.

=head1 FUNCTIONS

C<take> and C<drop> are exported by default; C<take_while> and
C<drop_while> on request, or all four with C<:all>. To have the
defaults and one more, name C<:DEFAULT> too:

    use DBIx::Squirrel::Stages::Flow qw(:DEFAULT take_while);

=head2 take

    take($count)

Passes on the first C<$count> values, then stops the pipeline. With
fewer values, passes them all on. C<take(0)> passes on none, but still
sees the first value, as a stage isn't called until there is one.

=head2 drop

    drop($count)

Drops the first C<$count> values, and passes on the rest. With
C<take>, it gives a page:

    drop(20), take(10)    # the 21st to the 30th

=head2 take_while

    take_while { ... }

Passes on values while the block is true of them, given each in C<$_>
and as its argument, then stops the pipeline at the first it's false
of, which isn't passed on.

=head2 drop_while

    drop_while { ... }

Drops values while the block is true of them, given each in C<$_> and
as its argument, and passes on the rest, from the first it's false of.
Once it's false, the block isn't called again on that run.

=head1 DIAGNOSTICS

=over

=item Expected a count of 0 or more

C<take> or C<drop> was given something other than a whole number.

=item Expected a code reference

C<take_while> or C<drop_while> was given something other than a block
or code reference.

=back

=head1 SEE ALSO

L<DBIx::Squirrel>, L<DBIx::Squirrel::Gather>, L<DBIx::Squirrel::Stop>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
