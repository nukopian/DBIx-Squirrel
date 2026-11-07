use v5.36;

package DBIx::Squirrel::Gather;

use Exporter qw(import);

use Ekorn::Pipeline::Gather;

# A facade over Ekorn::Pipeline::Gather, exporting what it exports,
# whatever that becomes.
our @EXPORT      = @Ekorn::Pipeline::Gather::EXPORT;        ## no critic (Modules::ProhibitAutomaticExportation)
our @EXPORT_OK   = @Ekorn::Pipeline::Gather::EXPORT_OK;
our %EXPORT_TAGS = %Ekorn::Pipeline::Gather::EXPORT_TAGS;

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel::Gather - a stage made afresh for each run, told when the values run out

=head1 SYNOPSIS

    use DBIx::Squirrel::Gather;

    # Rows in batches of $size, the last batch given at the end
    sub batches_of ($size) {
        return gather {
            my \@batch;    # this run's
            return (
                sub ($row) { push \@batch, $row; \@batch == $size ? [splice \@batch] : () },
                sub ()     { \@batch ? [\@batch] : () },
            );
        };
    }

    my $batches = $dbh->iterate('SELECT id, name FROM track', batches_of(500));
    while (my($batch) = $batches->next) { ... }

=head1 DESCRIPTION

DBIx::Squirrel's name for L<Ekorn::Pipeline::Gather>, which describes
C<gather> in full. It exports what that module exports: C<gather>, by
default. It's here to stay, so code written with it keeps working.

C<gather> makes a stage afresh at the start of each run of a pipeline:
each execution of an iterator or result set, and each call of a Sugar
statement or of a pipeline itself. Its block returns the stage, and
optionally a function called once the values have run out, whose
values go through the rest of the stages.

The stage it makes is an Ekorn::Pipeline::Gather, which is what a
pipeline looks for, so check for that class, not this one.

Inside an end function, and the stages it sends values to,
L<DBIx::Squirrel::Context/result_number> is the number of the result
being made, as in any stage. L<DBIx::Squirrel::Context/result_original>
is C<undef>, as what an end gives comes from many rows, not one.

To keep C<gather> out of your namespace:

    use DBIx::Squirrel::Gather ();

=head1 SEE ALSO

L<Ekorn::Pipeline::Gather>, L<DBIx::Squirrel>, L<DBIx::Squirrel::Context>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
