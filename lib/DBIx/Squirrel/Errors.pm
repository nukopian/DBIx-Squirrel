use v5.36;

package DBIx::Squirrel::Errors;

use experimental qw(try);

use Carp      qw(croak);
use Exporter  qw(import);
use Ref::Util qw(is_ref);

use namespace::clean -except => 'import';

our @EXPORT_OK = qw(at_caller croakf failed in_method);

# Croak at the line that called DBIx::Squirrel, past the DBI's own code
# and DBIx::Squirrel's.
our @CARP_NOT = qw(
    DBI            DBI::db            DBI::st
    DBD::_::common DBD::_::db         DBD::_::st
    DBIx::Squirrel DBIx::Squirrel::db DBIx::Squirrel::st
);

# Run a block calling the DBI, and return what it returns. If the DBI
# raises an error, as it does under RaiseError, at the line of the block,
# raise it again at the line that called DBIx::Squirrel. Any other error,
# such as an object, or a string from a HandleError callback, is raised
# again as it was.
#
# Each branch of the try returns or dies, which Perl::Critic can't see.
sub at_caller : prototype(&) ($code) {    ## no critic (Subroutines::RequireFinalReturn)
    my $file = (caller)[1];
    try {
        return $code->();
    }
    catch ($e) {
        die $e    ## no critic (ErrorHandling::RequireCarping)
            if is_ref($e);
        # Where Perl says a die happened, and the input it was reading.
        state $INPUT = qr( , \ <[^>]*> \ (?: line | chunk ) \ \d+ )x;
        my $at      = qr( \ at \ \Q$file\E \ line \ \d+ )x;
        my $message = $e =~ s( $at $INPUT? \. \n \z )()xr;
        die $e    ## no critic (ErrorHandling::RequireCarping)
            if $message eq $e;
        croak $message;
    }
}

# Croak with a message made by sprintf from a format and its arguments,
# as croak itself would, at the same line: goto leaves no frame of its
# own for Carp to see. It's a sub without a signature, as goto passes @_.
sub croakf {    ## no critic (Subroutines::RequireArgUnpacking)
    my $format = shift;
    @_ = (sprintf $format, @_);
    goto &Carp::croak;
}

# Return the message the DBI raises when a handle's method fails, as
# "DBD::SQLite::db prepare failed: ...".
sub failed ($h, $method) {
    return "$h->{ImplementorClass} $method failed: @{[ $h->errstr // '' ]}";
}

# Run code as a method of a database handle, and return what it returns.
# An error the DBI raises for a method the code calls, such as prepare or
# execute, is raised again as the DBI raises one for the handle's method,
# as "DBD::SQLite::db do failed: ...", as plain DBI does.
sub in_method ($dbh, $method, $code) {    ## no critic (Subroutines::RequireFinalReturn)
    try {
        return $code->();
    }
    catch ($e) {
        die $e    ## no critic (ErrorHandling::RequireCarping)
            if is_ref($e);
        state $DBI_FAILED = qr( \A DBD:: [\w:]+ :: (?: db | st ) \ \w+ \ failed: )x;
        die $e =~ s( $DBI_FAILED )("$dbh->{ImplementorClass} $method failed:")xer;    ## no critic (ErrorHandling::RequireCarping)
    }
}

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel::Errors - report the DBI's errors at the caller's line

=head1 SYNOPSIS

    use DBIx::Squirrel::Errors qw(at_caller);

    my $sth = at_caller { $self->SUPER::prepare($statement) };

=head1 DESCRIPTION

Under C<RaiseError>, the DBI reports an error at the line that called
it. Inside DBIx::Squirrel, that's a line of DBIx::Squirrel's own, which
is no help to its user. This module moves the error to the user's line.
Nothing is exported by default.

=head1 FUNCTIONS

=head2 at_caller

    @values = at_caller { ... };

Runs the block, which calls the DBI, and returns what it returns, in the
same context. If the block dies with a string located at the block's own
file, the location is removed and the message is raised again with
L<Carp/croak>, which reports it at the first line outside the DBI and
DBIx::Squirrel. The DBI's message itself, such as
C<DBD::SQLite::db prepare failed: ...>, is kept as it was. Any other
error, such as an object, or a string from a C<HandleError> callback, is
raised again unchanged.

=head2 croakf

    croakf 'Expected a value for each placeholder (none for %s)', $names;

Croaks with a message made by C<sprintf> from a format and its
arguments, reporting it at the same line as L<Carp/croak> would.

=head2 failed

    croak failed($dbh, 'prepare');

Returns the message the DBI raises under C<RaiseError> when a handle's
method fails, as C<DBD::SQLite::db prepare failed: ...>, for an error
DBIx::Squirrel raises itself.

=head2 in_method

    return in_method($dbh, 'do', sub { ... });

Runs the code as one method of a database handle, and returns what it
returns. An error the DBI raises for a method the code calls, such as
C<DBD::SQLite::st execute failed: ...>, is raised again as the DBI
raises one for the handle's method, C<DBD::SQLite::db do failed: ...>,
as plain DBI does. Any other error is raised again unchanged.

=head1 SEE ALSO

L<DBIx::Squirrel>, L<DBI/RaiseError>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
