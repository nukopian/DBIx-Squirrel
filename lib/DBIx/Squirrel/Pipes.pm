use v5.36;

package DBIx::Squirrel::Pipes;

use DBIx::Squirrel::Pipeline qw();

# Run the invocant through a pipeline of stages.
sub pipe ($self, @stages) {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    my $pipeline = DBIx::Squirrel::Pipeline->new(@stages);
    my @results  = $pipeline->($self);
    return wantarray ? @results : $results[0];
}

# Run the invocant through a pipeline of stages for their side-effects, and
# return the invocant.
sub tap ($self, @stages) {
    my $pipeline = DBIx::Squirrel::Pipeline->new(@stages);
    $pipeline->($self);
    return $self;
}

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel::Pipes - the pipe and tap methods of DBIx::Squirrel's handles

=head1 SYNOPSIS

    package My::Handle;

    our @ISA = ('Some::Parent', 'DBIx::Squirrel::Pipes');

=head1 DESCRIPTION

A parent class giving its children L<DBIx::Squirrel/pipe> and
L<DBIx::Squirrel/tap>. DBIx::Squirrel's database and statement handle
classes, L<DBIx::Squirrel::db> and L<DBIx::Squirrel::st>, inherit from
it as well as from the DBI's own.

=head1 SEE ALSO

L<DBIx::Squirrel>, L<DBIx::Squirrel::Pipeline>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
