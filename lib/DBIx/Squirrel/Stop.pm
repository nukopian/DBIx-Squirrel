use v5.36;

package DBIx::Squirrel::Stop;

use Carp     qw(croak);
use Exporter qw(import);

use namespace::clean -except => 'import';

use overload '""' => sub { "Stop used outside a pipeline\n" }, fallback => 1;

our @EXPORT = qw(Stop);    ## no critic (Modules::ProhibitAutomaticExportation)

# Syntactic sugar throwing the exception that stops a pipeline early.
sub Stop (@data) {
    return __PACKAGE__->throw(@data);
}

# Throws an exception that stops a pipeline early.
sub throw ($class, @data) {
    croak bless([$class, @data], $class);
}

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel::Stop - end a DBIx::Squirrel pipeline early

=head1 SYNOPSIS

    use DBIx::Squirrel::Stop;

    # In a stage of a pipeline
    sub ($row) { Stop() if $done; ... }

    # Stop, passing on a last value
    sub ($row) { $row->{id} == $wanted ? Stop($row) : () }

    # The same, without importing Stop
    sub ($row) { DBIx::Squirrel::Stop->throw if $done; ... }

=head1 DESCRIPTION

A stop is the exception that ends a DBIx::Squirrel pipeline early and
quietly. The rest of the stage that throws it doesn't run. The values
already out of the pipeline are kept, the values the stop carries go
on through the stages after it, and nothing else is processed.

=head1 FUNCTIONS

=head2 Stop

    Stop();
    Stop(@values);

Throws a stop carrying C<@values>, the last values of the stage that
throws it. It's the same as
C<< DBIx::Squirrel::Stop->throw(@values) >>, and is exported by
default.

To keep it out of your namespace:

    use DBIx::Squirrel::Stop ();

=head1 METHODS

=head2 throw

    DBIx::Squirrel::Stop->throw;
    DBIx::Squirrel::Stop->throw(@values);
    My::Stop->throw(@values);

Throws a stop carrying C<@values>, blessed into the class it was called
on, so a subclass of DBIx::Squirrel::Stop throws one of its own.

=head1 THE STOP

A stop is an array reference, blessed into its class. Its first element
is that class, and the rest are the values it was thrown with:

    eval { DBIx::Squirrel::Stop->throw(1, 2) };
    my $stop = $@;    # bless ['DBIx::Squirrel::Stop', 1, 2], 'DBIx::Squirrel::Stop'

A pipeline sends the values on through the stages after the one that
threw it, as that stage's last values.

As a string, a stop is "Stop used outside a pipeline", with a newline,
which is what a user sees if one is thrown with nothing to catch it.

=head2 Catching errors in a stage

A pipeline recognises a stop with C<isa>, so a subclass of
DBIx::Squirrel::Stop stops it too. A stage that catches errors
itself, with C<eval> or C<try>, should throw a stop on again:

    sub ($row) {
        try { ... }
        catch ($e) {
            die $e if $e isa 'DBIx::Squirrel::Stop';
            ...
        }
    }

=head1 DIAGNOSTICS

=over

=item Stop used outside a pipeline

A stop was thrown where no pipeline was running to catch it.

=back

=head1 SEE ALSO

L<DBIx::Squirrel>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
