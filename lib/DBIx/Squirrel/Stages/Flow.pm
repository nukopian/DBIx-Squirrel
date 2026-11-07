use v5.36;

package DBIx::Squirrel::Stages::Flow;

use Exporter qw(import);

use Ekorn::Pipeline::Stages::Flow qw(:all);

# A facade over Ekorn::Pipeline::Stages::Flow, exporting what it exports,
# whatever that becomes.
our @EXPORT      = @Ekorn::Pipeline::Stages::Flow::EXPORT;        ## no critic (Modules::ProhibitAutomaticExportation)
our @EXPORT_OK   = @Ekorn::Pipeline::Stages::Flow::EXPORT_OK;
our %EXPORT_TAGS = %Ekorn::Pipeline::Stages::Flow::EXPORT_TAGS;

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel::Stages::Flow - stages taking or dropping values: take, drop, take_while and drop_while

=head1 SYNOPSIS

    use DBIx::Squirrel::Stages::Flow;

=head1 DESCRIPTION

DBIx::Squirrel's name for L<Ekorn::Pipeline::Stages::Flow>, which
describes its stages in full: C<take>, C<drop>, C<take_while> and C<drop_while>. It exports what that module exports,
by default and on request, so a stage added there is here too. It's
here to stay, beside DBIx::Squirrel's own stages, such as
L<DBIx::Squirrel::Stages::Rows>.

=head1 SEE ALSO

L<Ekorn::Pipeline::Stages::Flow>, L<DBIx::Squirrel>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
