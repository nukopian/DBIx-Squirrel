use v5.36;

package DBIx::Squirrel::st;

use Carp      qw(croak);
use DBI       qw();
use Ref::Util qw(is_arrayref is_hashref);

use DBIx::Squirrel::Errors   qw(at_caller croakf);
use DBIx::Squirrel::Iterator qw();
use DBIx::Squirrel::Results  qw();
use DBIx::Squirrel::Pipes    qw();

use namespace::clean;

our @ISA = ('DBI::st', 'DBIx::Squirrel::Pipes');

# Croak at the line that called DBIx::Squirrel, past the DBI's own code,
# which calls execute from its select methods, and DBIx::Squirrel's.
our @CARP_NOT = qw(
    DBI            DBI::db            DBI::st
    DBD::_::common DBD::_::db         DBD::_::st
    DBIx::Squirrel DBIx::Squirrel::db DBIx::Squirrel::Errors
);

# Bind values to the statement's placeholders, without executing it, and
# return the handle, or nothing if the DBI couldn't bind one. Numbered
# placeholders take values in order, the first to every use of 1, and so
# on; named ones take a hash reference or a list of names and values. An
# array reference stands for the values in it.
sub bind ($self, @args) {
    return _bind($self, _unwrap($self, @args));
}

# Bind values, as bind does, given as a list.
sub _bind ($self, @args) {
    my $binds = _binds($self);
    unless ($binds) {
        for my $position (1 .. @args) {
            at_caller { $self->SUPER::bind_param($position, $args[$position - 1]) }
                or return;
        }
        return $self;
    }
    my %values = _values_for($binds, @args);
    for my $key (sort keys %values) {
        $self->bind_param($key, $values{$key}) or return;
    }
    return $self;
}

# Bind a value to a placeholder, as the DBI's bind_param does, given its
# number or its name, with or without the sigil, and bind it to every use
# of that placeholder in the statement. Return what the DBI returns.
sub bind_param ($self, $param, $value, @attrs) {
    my $binds = _binds($self)
        or return at_caller { $self->SUPER::bind_param($param, $value, @attrs) };
    my $positions = $binds->{_key($param)};
    unless ($positions) {

        # A position, for a statement with named placeholders.
        return at_caller { $self->SUPER::bind_param($param, $value, @attrs) }
        if $param =~ m( \A \d+ \z )x && !_numbered($binds);
        croak "Expected a placeholder of the statement ($param)";
    }
    my $rv;
    for my $position (@$positions) {
        $rv = at_caller { $self->SUPER::bind_param($position, $value, @attrs) }
            or return $rv;
    }
    return $rv;
}

# Execute the statement, as the DBI's execute does, binding any values
# given as bind does first. With the ekorn_finish_active attribute, a
# statement still active from an earlier execute is finished first.
sub execute ($self, @args) {
    my $state = $self->{private_ekorn};
    $self->finish
        if $self->{Active} && $state && $state->{Options}{ekorn_finish_active};
    @args = _unwrap($self, @args);
    return at_caller { $self->SUPER::execute(@args) }
    unless @args && _binds($self);
    _bind($self, @args) or return;
    return at_caller { $self->SUPER::execute };
}

# Return an iterator over the statement's results, executed with the bind
# values given, and run through the stages given after them.
sub iterate ($self, @args) {
    return DBIx::Squirrel::Iterator->new($self, @args);
}

# Return a result set over the statement's results: an iterator handing
# out rows as objects.
sub results ($self, @args) {
    return DBIx::Squirrel::Results->new($self, @args);
}

# Return the values given, or those in an array reference given alone,
# unless it's a value itself. DBD::Pg binds an array reference as a
# PostgreSQL array, so, with DBD::Pg, one given to a statement taking one
# value is that value, as it would be with the DBI.
sub _unwrap ($self, @args) {
    return @args
        unless @args == 1 && is_arrayref($args[0]);
    return @args
        if $self->{Database}{Driver}{Name} eq 'Pg' && _values_taken($self) == 1;
    return @{ $args[0] };
}

# Return how many values the statement takes in order: one for each
# placeholder the DBI sees, or each number, or none if they're named.
sub _values_taken ($self) {
    my $binds = _binds($self)
        or return $self->{NUM_OF_PARAMS};
    return 0
        unless _numbered($binds);
    my($highest) = sort { $b <=> $a } keys %$binds;
    return $highest;
}

# Return the statement's map of each placeholder's number or name to its
# positions, or nothing if the statement went to the DBI as written.
sub _binds ($self) {
    my $state = $self->{private_ekorn};
    return $state && $state->{Binds};
}

# Return a placeholder's number or name, as the statement's map keys it.
sub _key ($param) {
    my $key = $param =~ s( \A [?:\$] )()xr;
    return $key =~ m( \A \d+ \z )x ? 0+ $key : $key;
}

# Return true if a statement's placeholders are numbered, not named.
sub _numbered ($binds) {
    my($key) = keys %$binds;
    return $key =~ m( \A \d+ \z )x;
}

# Return each placeholder's number or name, with the value given for it,
# croaking unless there's a value for each, and no other.
sub _values_for ($binds, @args) {
    if (_numbered($binds)) {
        my($needed) = sort { $b <=> $a } keys %$binds;
        croakf 'Expected %d bind values, not %d', $needed, scalar @args
            unless @args == $needed;
        return map { ($_ => $args[$_ - 1]) } keys %$binds;
    }
    my %values;
    if (@args == 1 && is_hashref($args[0])) {
        %values = %{ $args[0] };
    }
    else {
        croak 'Expected names and values in pairs'
            if @args % 2;
        %values = @args;
    }
    my %given   = map       { (_key($_) => $values{$_}) } keys %values;
    my @unknown = sort grep { !$binds->{_key($_)} } keys %values;
    croakf 'Expected a placeholder of the statement (%s)', join ', ', @unknown
        if @unknown;
    my @missing = sort grep { !exists $given{$_} } keys %$binds;
    croakf 'Expected a value for each placeholder (none for %s)',
        join(', ', @missing)
        if @missing;
    return %given;
}

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel::st - DBIx::Squirrel's statement handle class

=head1 DESCRIPTION

A statement handle prepared on a DBIx::Squirrel database handle is
blessed into this class, a subclass of the DBI's C<DBI::st>, so it does
everything a DBI statement handle does. It also inherits
L<DBIx::Squirrel/pipe> and L<DBIx::Squirrel/tap> from
L<DBIx::Squirrel::Pipes>.

=head1 METHODS

=head2 bind

    $sth = $sth->bind(@bind_values);
    $sth = $sth->bind(\@bind_values);
    $sth = $sth->bind(%values);
    $sth = $sth->bind(\%values);

Binds values to the statement's placeholders, as L</execute> does,
without executing it, and returns the statement handle, or nothing if
the DBI couldn't bind a value. How the values are matched to
placeholders depends on the statement's style of placeholder:

=over

=item C<?>

Values are bound in order, as with the DBI.

=item C<?1>, C<:1> and C<$1>

The first value is bound to every use of placeholder 1, the second to
every use of 2, and so on, wherever they are in the statement. There
must be as many values as the highest number. In
C<SELECT $2 + $1, $1>, C<(10, 20)> gives C<SELECT 20 + 10, 10>.

=item C<:name> and C<$name>

Values are given by name, as pairs or in a hash reference, and each is
bound to every use of its name. The names can be given with or without
the sigil. There must be a value for each name, and no other:

    $sth->bind(id => 1, name => 'AC/DC');
    $sth->bind({':id' => 1, ':name' => 'AC/DC'});

=back

A single array reference stands for the values in it, so
C<< $sth->bind([1, 2]) >> is C<< $sth->bind(1, 2) >>. The exception is
L<DBD::Pg>, which binds an array reference as a PostgreSQL array: with
DBD::Pg, an array reference given to a statement taking one value, such
as C<SELECT * FROM artist WHERE id = ANY(?)>, is that value, as it would
be with the DBI. Through another driver, such as DBD::ODBC, it's
unwrapped as usual, as the driver can't bind arrays.

=head2 bind_param

    $rv = $sth->bind_param($placeholder, $value);
    $rv = $sth->bind_param($placeholder, $value, \%attr);
    $rv = $sth->bind_param($placeholder, $value, $bind_type);

Binds a value, as the DBI's C<bind_param> does, and returns what it
returns. The placeholder can be given by number, for numbered
placeholders, or by name, with or without its sigil, for named ones, and
the value is bound to every use of it in the statement. A statement with
named placeholders can also be bound by position, as with the DBI.

=head2 execute

    $rv = $sth->execute;
    $rv = $sth->execute(@bind_values);
    $rv = $sth->execute(\@bind_values);
    $rv = $sth->execute(%values);
    $rv = $sth->execute(\%values);

Executes the statement, as the DBI's C<execute> does, and returns what
it returns. Values given are bound first, as L</bind> binds them.

The DBI doesn't finish a statement still active from an earlier
C<execute> before executing it again, and nor does C<execute>, unless the
C<ekorn_finish_active> attribute is true. It can be set for every
statement of a database handle, passed to L<DBIx::Squirrel/connect>, or
for one statement, passed to L<DBIx::Squirrel::db/prepare>.

=head2 iterate

    $it = $sth->iterate(@bind_values, @stages);

Returns a L<DBIx::Squirrel::Iterator>, an iterator over the statement's
results, executed with C<@bind_values>, in any form L</execute> takes,
and run through C<@stages>, the code references at the end of the
arguments. The statement is executed when the first result is asked for.

=head2 results

    $results = $sth->results(@bind_values, @stages);

Returns a L<DBIx::Squirrel::Results>, as L</iterate> does, whose rows
are objects with a method for each column.

=head1 DIAGNOSTICS

=over

=item Expected %d bind values, not %d

A statement with numbered placeholders was given more or fewer values
than its highest number.

=item Expected names and values in pairs

A statement with named placeholders was given an odd number of values.

=item Expected a placeholder of the statement (%s)

A value was given for a placeholder the statement doesn't have.

=item Expected a value for each placeholder (none for %s)

A statement with named placeholders wasn't given a value for each name.

=back

=head1 SEE ALSO

L<DBIx::Squirrel>, L<DBI>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
