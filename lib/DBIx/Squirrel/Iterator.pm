use v5.36;

package DBIx::Squirrel::Iterator;

use Carp         qw(croak);
use Ref::Util    qw(is_coderef);
use Scalar::Util qw(weaken);

use DBIx::Squirrel::Context  qw();
use DBIx::Squirrel::Pipeline qw();

use namespace::clean;

# Croak at the line that called DBIx::Squirrel, past its own code and the
# DBI's.
our @CARP_NOT = qw(
    DBIx::Squirrel         DBIx::Squirrel::db       DBIx::Squirrel::st
    DBIx::Squirrel::Errors DBIx::Squirrel::Pipeline DBIx::Squirrel::Context
);

# How many rows are fetched at a time.
my $BATCH_SIZE = 100;

# Return a new iterator over the rows of a statement handle, executed with
# the bind values given, and run through the stages given after them.
sub new ($class, $sth, @args) {
    croak 'Expected a statement handle'
        unless $sth isa 'DBIx::Squirrel::st';
    my @stages = _split_stages(\@args);
    return bless {
        sth                 => $sth,
        bind_values_initial => \@args,
        stages_initial      => \@stages,
    }, $class;
}


# Return the next result, or nothing when there are no more, executing the
# statement first if it hasn't been.
sub next ($self) {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    _executed($self);
    return _take($self);
}


# Return the results not yet fetched, or, in scalar context, how many
# there were.
sub all ($self) {
    _executed($self);
    my @results;
    push @results, _take($self) while _peek($self);
    return @results;
}


# Execute the statement again, and return its one result, or nothing if
# it has none, croaking if it has more than one.
sub single ($self) {
    $self->reset;
    my($result) = _take($self) or return;
    my $more = _peek($self);
    _finish($self);
    croak 'Expected one result, not more' if $more;
    return $result;
}


# Execute the statement again, ready to iterate from its first row, and
# return the iterator. Bind values given replace those given before;
# stages given are added to those given to new. Both are kept until
# others are given.
sub reset ($self, @args) {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    my $sth   = $self->{sth};
    my $state = $sth->{private_ekorn} //= {};
    my $other = $state->{Iterator};
    croak "Expected the statement handle's other iterator to be finished"
        if $other && $other != $self && $other->{executed} && !$other->{done};

    my @stages = _split_stages(\@args);
    $self->{stages}        = [@{ $self->{stages_initial} }, @stages] if @stages;
    $self->{stages}      //= [@{ $self->{stages_initial} }];
    $self->{bind_values}   = \@args if @args;
    $self->{bind_values} //= [@{ $self->{bind_values_initial} }];

    $sth->finish if $sth->{Active};
    $state->{Iterator} = $self;
    weaken $state->{Iterator};
    %$self = (
        %$self,
        executed  => 1,
        done      => 0,
        buffer    => [],
        lookahead => undef,
        count     => 0,
        produced  => 0,
        original  => undef,
        slice     => $self->_slice,
    );
    $self->{done} = 1
        unless defined $sth->execute(@{ $self->{bind_values} });
    my $pipeline = DBIx::Squirrel::Pipeline->new(@{ $self->{stages} });
    $self->{next} = $pipeline->iterator(_source($self));
    return $self;
}


# Return the number of results fetched so far.
sub count ($self) {
    return $self->{count} // 0;
}


sub sth ($self) {
    return $self->{sth};
}


# Execute the statement, unless it's been executed.
sub _executed ($self) {
    $self->reset unless $self->{executed};
    return;
}


# Take the next result, returning it as a list of one, or an empty list
# when there are no more.
sub _take ($self) {
    _peek($self) or return;
    my($result) = @{ delete $self->{lookahead} };
    $self->{count}++;
    return $result;
}


# Run the stages until the next result comes out of them, and keep it, so
# a result can be looked for without being taken. Return true if there's
# one.
sub _peek ($self) {
    return 1 if $self->{lookahead};
    return 0 if $self->{done};
    my @result = DBIx::Squirrel::Context::within(
        {
            iterator => $self,
            number   => $self->{produced} + 1,
            original => $self->{original},
        },
        $self->{next},
    );
    unless (@result) {
        _finish($self);
        return 0;
    }
    $self->{lookahead} = \@result;
    $self->{produced}++;
    return 1;
}


# Stop iterating, and finish the statement.
sub _finish ($self) {
    @$self{qw(done lookahead buffer)} = (1, undef, []);
    $self->{sth}->finish if $self->{sth}{Active};
    return;
}


# Return a source for the pipeline: a closure returning the statement's
# next row, fetched a batch at a time, or nothing.
sub _source ($self) {
    weaken $self;
    return sub () {
        my $buffer = $self->{buffer};
        unless (@$buffer) {
            my $sth = $self->{sth};
            return unless $sth->{Active} && $sth->{NUM_OF_FIELDS};
            my $rows = $sth->fetchall_arrayref($self->{slice}, $BATCH_SIZE);
            return unless $rows && @$rows;
            push @$buffer, @$rows;
        }
        $self->{original} = $self->_row(shift @$buffer);
        DBIx::Squirrel::Context::set_original($self->{original});
        return $self->{original};
    };
}


# Return the slice rows are fetched as: the ekorn_slice attribute, or
# arrays; a subclass can choose its own.
sub _slice ($self) {
    return $self->{sth}{private_ekorn}{Options}{ekorn_slice} // [];
}


# Return a row as the stages are to see it: as it was fetched, here; a
# subclass can make something else of it.
sub _row ($self, $row) {
    return $row;
}


# Take the code references off the end of a list of arguments, and return
# them.
sub _split_stages ($args) {
    my $n = @$args;
    $n -= 1 while $n && is_coderef($args->[$n - 1]);
    return splice @$args, $n;
}

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel::Iterator - an iterator over a statement's results

=head1 SYNOPSIS

    my $it = $dbh->iterate(
        'SELECT id, name FROM artist WHERE name LIKE :pattern',
        pattern => 'A%',
        sub ($row) { $row->[1] },
    );
    while (my($name) = $it->next) {
        say $name;
    }

    my $sth = $dbh->prepare(
        'SELECT * FROM artist WHERE id = $1',
        {ekorn_slice => {}},
    );
    my $artist = $sth->iterate(42)->single;

=head1 DESCRIPTION

An iterator executes a statement and hands out its rows one at a time,
each run through a pipeline of stages, as L<DBIx::Squirrel::Pipeline>
runs them: a stage can change a row, drop it, return several values in
its place, or stop the iteration with L<DBIx::Squirrel::Stop>. A result
is whatever comes out of the stages; with none, it's the row. A stage
can ask about the result it's making with L<DBIx::Squirrel::Context>.

An iterator is made by L<DBIx::Squirrel::db/iterate> or
L<DBIx::Squirrel::st/iterate>. It executes the statement when its first
result is asked for, and finishes the statement when the results run
out.

Rows are fetched 100 at a time, with L<DBI/fetchall_arrayref>, each as
an array, or, with the C<ekorn_slice> attribute, in the shape it gives:

    $dbh = DBIx::Squirrel->connect($dsn, $user, $pass, {ekorn_slice => {}});
    $sth = $dbh->prepare($statement, {ekorn_slice => {}});

C<ekorn_slice> is a slice as L<DBI/fetchall_arrayref> takes it: an
array reference, for rows as arrays, or a hash reference, for rows as
hashes. Given to C<connect>, it's the default for each statement the
handle prepares; given to C<prepare>, it's for that statement.

One statement handle can have one iterator going through its results
at a time.

=head1 METHODS

=head2 new

    $it = DBIx::Squirrel::Iterator->new($sth, @bind_values, @stages);

Returns an iterator over the rows of C<$sth>, a L<DBIx::Squirrel::st>,
executed with C<@bind_values>, in any form L<DBIx::Squirrel::st/execute>
takes, and run through C<@stages>, the code references at the end of the
arguments. It doesn't execute the statement.

=head2 next

    while (my($result) = $it->next) { ... }

Returns the next result, or an empty list when there are no more. A
stage can return C<undef> as a result, so read C<next> in list context,
as above, rather than testing whether what it returns is defined.

=head2 all

    @results = $it->all;
    $count   = $it->all;

Returns the results not yet fetched, or, in scalar context, how many
there were. Either way, they're fetched, and C<next> returns nothing
after.

=head2 single

    $result = $it->single;

Executes the statement again, and returns its one result, or nothing if
it has none. It croaks if there's more than one. Either way, it's done:
C<next> returns nothing after.

=head2 reset

    $it = $it->reset;
    $it = $it->reset(@bind_values, @stages);

Executes the statement again, ready to iterate from its first row,
finishing it first if it's still active, and returns the iterator. Bind
values given replace those given before. Stages given are added to those
given to L</new>. Both are kept until others are given.

=head2 count

    $n = $it->count;

Returns the number of results fetched so far.

=head2 sth

    $sth = $it->sth;

Returns the statement handle.

=head1 DIAGNOSTICS

=over

=item Expected a statement handle

L</new> wasn't given a L<DBIx::Squirrel::st>.

=item Expected one result, not more

L</single> found a second result.

=item Expected the statement handle's other iterator to be finished

The iterator's statement handle has another iterator, which has
results left to hand out. Read that one to the end, or let it go out of
scope, before executing this one.

=back

=head1 SEE ALSO

L<DBIx::Squirrel>, L<DBIx::Squirrel::Context>,
L<DBIx::Squirrel::Pipeline>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
