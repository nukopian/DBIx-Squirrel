use v5.36;

package DBIx::Squirrel::Stages::Taps;

use Exporter qw(import);

use Ekorn::Pipeline::Stages::Taps qw(:all);

# A facade over Ekorn::Pipeline::Stages::Taps, exporting what it exports,
# whatever that becomes.
our @EXPORT      = @Ekorn::Pipeline::Stages::Taps::EXPORT;        ## no critic (Modules::ProhibitAutomaticExportation)
our @EXPORT_OK   = @Ekorn::Pipeline::Stages::Taps::EXPORT_OK;
our %EXPORT_TAGS = %Ekorn::Pipeline::Stages::Taps::EXPORT_TAGS;

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel::Stages::Taps - stages run for their side effects: peek, count_into and dump_to

=head1 SYNOPSIS

    use DBIx::Squirrel::Stages::Taps;

=head1 DESCRIPTION

DBIx::Squirrel's name for L<Ekorn::Pipeline::Stages::Taps>, which
describes its stages in full: C<peek>, C<count_into> and C<dump_to>. It exports what that module exports,
by default and on request, so a stage added there is here too. It's
here to stay, beside DBIx::Squirrel's own stages, such as
L<DBIx::Squirrel::Stages::Rows>.

=head1 SEE ALSO

L<Ekorn::Pipeline::Stages::Taps>, L<DBIx::Squirrel>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
