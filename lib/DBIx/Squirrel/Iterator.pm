use v5.36;

package DBIx::Squirrel::Iterator;

use experimental qw(builtin);

use builtin qw(weaken);

use List::Util qw(min);
use Ref::Util  qw(is_plain_arrayref);

use Ekorn::Pipeline            qw();
use Ekorn::Pipeline::Factories qw(source);

use DBIx::Squirrel::Context qw();
use DBIx::Squirrel::Errors  qw(at_caller      croakf);
use DBIx::Squirrel::Util    qw(iterator_going split_stages);

use namespace::clean;

# Croak at the line that called DBIx::Squirrel.
our @CARP_NOT = @DBIx::Squirrel::Errors::INTERNAL;

# How many rows are fetched at a time: 2 at first, the least that tells
# whether there's a second, doubling each time a fetch fills its batch,
# up to 64, as in version 1.
my $BATCH_FIRST = 2;
my $BATCH_LIMIT = 64;

# Return a new iterator over the rows of a statement handle, executed with
# the bind values given, and run through the stages given after them.
sub new ($class, $sth, @args) {
    croakf 'Expected a statement handle'
        unless $sth isa 'DBIx::Squirrel::st';
    my @stages = split_stages(\@args);
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
    return if $self->{done};
    my @result = DBIx::Squirrel::Context::within($self, $self->{run});
    unless (@result) {
        _finish($self);
        return;
    }
    return $result[0];
}

# Return the results still to come, reading the run to its end: as a
# list, or, asked for one value, an array reference of them. Without
# stages, the source gives every row left in one step.
sub all ($self) {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    _executed($self);
    my $all = [];
    unless ($self->{done}) {
        local $self->{all_at_once} = !@{ $self->{stages} };
        my $run = $self->{run};
        $all = DBIx::Squirrel::Context::within($self, sub { scalar $run->all });
        _finish($self);
    }
    return wantarray ? @$all : $all;
}

# Return the next result, or undef if there's none, and finish the run.
sub first ($self) {
    _executed($self);
    return undef if $self->{done};    ## no critic (Subroutines::ProhibitExplicitReturnUndef)
    my $run    = $self->{run};
    my $result = DBIx::Squirrel::Context::within($self, sub { $run->first });
    _finish($self);
    return $result;
}

# Return the next result, or undef if there's none, warning if there's
# another, and finish the run.
sub single ($self) {
    _executed($self);
    return undef if $self->{done};    ## no critic (Subroutines::ProhibitExplicitReturnUndef)
    my $run    = $self->{run};
    my $result = DBIx::Squirrel::Context::within($self, sub { $run->single });
    _finish($self);
    return $result;
}

# Execute the statement again, ready to iterate from its first row, and
# return the iterator. Whatever the run before held goes with it. Bind
# values given replace those given before; stages given are added to
# those given to new. Both are kept until others are given. A statement
# with list placeholders is prepared again, on a new statement handle, if
# a list has a different number of values.
sub reset ($self, @args) {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    my $other = iterator_going($self->{sth});
    croakf "Expected the statement handle's other iterator to be finished"
        if $other && $other != $self;

    my @stages = split_stages(\@args);
    $self->{stages}        = [@{ $self->{stages_initial} }, @stages] if @stages;
    $self->{stages}      //= [@{ $self->{stages_initial} }];
    $self->{bind_values}   = \@args if @args;
    $self->{bind_values} //= [@{ $self->{bind_values_initial} }];

    _finish($self);
    my $sth   = $self->{sth};
    my $state = $sth->{private_ekorn};
    if ($state->{Lists}) {
        my $again = DBIx::Squirrel::db::_prepare_again(    ## no critic (Subroutines::ProtectPrivateSubs)
            $sth->{Database}, $sth, @{ $self->{bind_values} },
        );
        if ($again != $sth) {
            delete $state->{Iterator};
            ($sth, $state) = ($self->{sth} = $again, $again->{private_ekorn});
        }
    }
    $state->{Iterator} = $self;
    weaken $state->{Iterator};
    # An empty array slice fetches every column, as no slice does, but the
    # DBI takes its slower way given one, so it's given none.
    my $slice = $self->_slice;
    $slice = undef if is_plain_arrayref($slice) && !@$slice;
    my %fresh = (
        executed     => 1,
        done         => 0,
        produced     => 0,
        original     => undef,
        column_names => [],
        slice        => $slice,
    );
    @$self{keys %fresh} = values %fresh;
    # The source's set-up executes the statement, as the run starts. The
    # stages, if any, are followed by one counting the results, for
    # DBIx::Squirrel::Context, unless the last is a sink, whose result is
    # the run's.
    my @counted = @{ $self->{stages} };
    if (@counted && !Ekorn::Pipeline::is_sink($counted[-1])) {
        my $counter = $self;
        weaken $counter;
        push @counted, sub ($result) { $counter->{produced}++; $result };
    }
    $self->{run} = Ekorn::Pipeline->new(@counted)->iterator(_statement($self));
    return $self;
}

# Return the names of the statement's columns, as fetchrow_hashref keys
# them, executing the statement first if it hasn't been.
sub column_names ($self) {
    _executed($self);
    return @{ $self->{column_names} // [] };
}


sub sth ($self) {
    return $self->{sth};
}

# An iterator is a source: each run reads the statement afresh, from its
# first row, through the iterator's stages, passing on the statement's
# columns as the run's context.
sub ekorn_source ($self) {
    $self->reset;
    return $self->{run}->ekorn_source;
}

# Execute the statement, unless it's been executed.
sub _executed ($self) {
    $self->reset unless $self->{executed};
    return;
}

# End the run, if one is going, and finish the statement. What the run
# held goes with it: its batch, and anything its Ekorn iterator holds.
sub _finish ($self) {
    my $run = delete $self->{run};
    $run->finish if $run;
    $self->{done} = 1;
    my $sth = $self->{sth};
    $sth->finish if $sth->{Active};
    return;
}

# Return a source of the statement's rows, made for each run: its set-up
# executes the statement and reads the columns' names; its step gives the
# next row, from a batch of the run's own, fetched as needed, or every row
# left at once when all asks for them without stages; its end finishes
# the statement. A run's end touches only its own run, as the iterator
# ends a run before it starts another. The run keeps what it needs
# itself, so it reads on if the iterator is let go first, as when a
# pipeline reads it. A subclass can make something else of each row,
# before the stages see it, with a _row method of its own, as
# DBIx::Squirrel::Results does.
sub _statement ($self) {
    my $row = $self->can('_row');
    weaken $self;
    return source {
        my $sth   = $self->{sth};
        my $slice = $self->{slice};
        my @binds = @{ $self->{bind_values} };
        my @buffer;
        my $batch = $BATCH_FIRST;
        my $done  = !defined $sth->execute(@binds);
        my @names;
        # The names are read now, before a row is fetched: once the last
        # row is, DBD::mysql gives none, unless they were read before.
        unless ($done) {
            my $key = $sth->{FetchHashKeyName} || 'NAME';
            @names = at_caller { $sth->{NUM_OF_FIELDS} ? @{ $sth->{$key} } : () };
        }
        $self->{column_names} = [@names];
        my $fetch = sub ($size) {
            return at_caller {
                $sth->{Active} && $sth->{NUM_OF_FIELDS}
                    ? $sth->fetchall_arrayref($slice, $size)
                    : undef;
            };
        };
        my $made = sub (@rows) {
            return @rows unless $self;
            @rows             = map { $self->$row($_) } @rows if $row;
            $self->{original} = $rows[-1]                     if @rows;
            return @rows;
        };
        my $step = sub () {
            return if $done;
            if ($self && $self->{all_at_once}) {
                my @rows = splice @buffer;
                my $rest = $fetch->(undef);
                push @rows, @$rest if $rest;
                $done = 1;
                return $made->(@rows);
            }
            unless (@buffer) {
                my $rows = $fetch->($batch);
                unless ($rows && @$rows) {
                    $done = 1;
                    return;
                }
                $batch  = min($batch * 2, $BATCH_LIMIT) if @$rows >= $batch;
                @buffer = @$rows;
            }
            return $made->(shift @buffer);
        };
        my $end = sub ($how) {
            @buffer = ();
            # At program exit, the database may have gone already.
            return       if ${^GLOBAL_PHASE} eq 'DESTRUCT';
            $sth->finish if $sth->{Active};
            return;
        };
        return ($step, $end, {columns => [@names], statement => $sth});
    };
}

# Return the slice rows are fetched as: the ekorn_slice attribute, or
# arrays; a subclass can choose its own.
sub _slice ($self) {
    return $self->{sth}{private_ekorn}{Options}{ekorn_slice} // [];
}

1;
__END__

=encoding utf8

=for stopwords sth

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

    # A stage can leave its signature out, and use $_
    my @names = $dbh->iterate('SELECT id, name FROM artist', sub { $_->[1] })->all;

    my $sth = $dbh->prepare(
        'SELECT * FROM artist WHERE id = $1',
        {ekorn_slice => {}},
    );
    my $artist = $sth->iterate(42)->single;

=head1 DESCRIPTION

An iterator executes a statement and hands out its rows one at a time.
Each row is run through a pipeline of stages, as
L<DBIx::Squirrel::Pipeline> runs them. A stage can change a row, drop
it, return several values in its place, or stop the iteration with
L<DBIx::Squirrel::Stop>. A result is whatever comes out of the stages.
With no stages, it's the row. A stage can ask about the result it's
making with L<DBIx::Squirrel::Context>.

An iterator is made by L<DBIx::Squirrel::db/iterate> or
L<DBIx::Squirrel::st/iterate>. It executes the statement when its first
result is asked for, and finishes the statement when the results run
out.

Rows are fetched with L<DBI/fetchall_arrayref>, 2 at first, the least
that tells whether there's a second, then twice as many each time a
fetch fills its batch, up to 64. L</all> without stages fetches the
rest at once. Each row is an array, or,
with the C<ekorn_slice> attribute, in the shape it gives:

    $dbh = DBIx::Squirrel->connect($dsn, $user, $pass, {ekorn_slice => {}});
    $sth = $dbh->prepare($statement, {ekorn_slice => {}});

C<ekorn_slice> is a slice as L<DBI/fetchall_arrayref> takes it: an
array reference, for rows as arrays, or a hash reference, for rows as
hashes. Given to C<connect>, it's the default for each statement the
handle prepares. Given to C<prepare>, it's for that statement.

A statement handle can have only one iterator going through its
results at a time.

=head1 METHODS

=head2 new

    $it = DBIx::Squirrel::Iterator->new($sth, @bind_values, @stages);

Returns an iterator over the rows of C<$sth>, a L<DBIx::Squirrel::st>.
It doesn't execute the statement. When it does, it's executed with
C<@bind_values>, in any form L<DBIx::Squirrel::st/execute> takes. Each
row is run through C<@stages>, the code references or pipelines at the
end of the arguments.

=head2 next

    while (my($result) = $it->next) { ... }

Returns the next result, or an empty list when there are no more. A
stage can return C<undef> as a result. So read C<next> in list
context, as above, rather than testing whether what it returns is
defined.

Once a stage dies, the iterator has ended. C<next> returns an empty
list on every call after, C<all> returns nothing, and the statement is
finished. L</reset> runs it again, from the start.

=head2 all

    @results = $it->all;
    $results = $it->all;

Returns the results still to come, reading the run to its end: as a
list, or, asked for one value, an array reference of them. Either way,
the statement is finished, and C<next> returns nothing after.

Without stages, the rows are the results. So C<all> takes what's left
of the batch fetched last, and fetches the rest with one
C<fetchall_arrayref>. That's nearly as quick as the DBI's own
C<selectall_arrayref>. With stages, each row goes through them in
turn, which costs a little for each row. So to change every row of a
large result, when nothing needs to stop early, C<map> over C<all> is
quicker than a stage:

    my @names = map { $_->[0] } $dbh->iterate('SELECT name FROM artist')->all;

Use stages when the rows should come one at a time, from C<next>, or
may stop early, or should go with the statement, as in a Sugar
statement.

=head2 first

    $result = $it->first;

Returns the next result, or C<undef> if there's none, and finishes the
statement. C<next> returns nothing after, until L</reset>.

=head2 single

    $result = $it->single;

Returns the next result, or C<undef> if there's none, and finishes the
statement. If there's another, it warns, and returns the first: for a
statement that lost its C<LIMIT 1>. C<next> returns nothing after,
until L</reset>.

=head2 reset

    $it = $it->reset;
    $it = $it->reset(@bind_values, @stages);

Executes the statement again, ready to iterate from its first row, and
returns the iterator. If the statement is still active, it's finished
first, and whatever the run before held goes with it. Bind values given replace those given before. Stages given are
added to those given to L</new>. Both are kept until others are given.

A statement taking a list (see L<DBIx::Squirrel::st/Lists>) is
prepared again, on a new statement handle, if a list given has a
different number of values from the one before. L</sth> then returns
the new handle.

=head2 column_names

    @names = $it->column_names;

Returns the names of the statement's columns, as C<fetchrow_hashref>
would key them, following the C<FetchHashKeyName> attribute. If the
statement hasn't been executed, it's executed first. The names are
read when it's executed, as some drivers, such as DBD::mysql, give
none once the last row is fetched. A statement without columns has no
names, and nor does one that couldn't be executed. A stage can ask for
them through L<DBIx::Squirrel::Context/iterator>.

=head2 sth

    $sth = $it->sth;

Returns the statement handle. It changes if L</reset> prepares a
statement taking a list again.

=head2 ekorn_source

An iterator is a source, as L<Ekorn::Pipeline> takes one: a run
reading it executes the statement again, from its first row, through
the iterator's stages, and passes on the statement's columns as the
run's context. It's called by Ekorn::Pipeline, not by you.

=head1 DIAGNOSTICS

=over

=item Expected a statement handle

L</new> wasn't given a L<DBIx::Squirrel::st>.

=item Expected only one item, but there were more

A warning: L</single> found a second result, and returned the first.

=item Expected the statement handle's other iterator to be finished

The iterator's statement handle has another iterator, with results
left to hand out. Read that one to the end, or let it go out of scope,
before executing this one.

=back

=head1 SEE ALSO

L<DBIx::Squirrel>, L<DBIx::Squirrel::Context>,
L<DBIx::Squirrel::Pipeline>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
