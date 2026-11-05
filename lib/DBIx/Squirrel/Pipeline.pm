use v5.36;

package DBIx::Squirrel::Pipeline;

use experimental qw(try);

use Carp      qw(croak);
use Ref::Util qw(is_coderef is_ref);

use DBIx::Squirrel::Errors qw(croakf);

use namespace::clean;

use overload '&{}' => sub ($self, @) { $self->{call} }, fallback => 1;

# Croak at the line that called DBIx::Squirrel.
our @CARP_NOT = @DBIx::Squirrel::Errors::INTERNAL;

# Return a pipeline, called with values to run each of them through the
# stages.
sub new ($class, @stages) {
    for my $n (1 .. @stages) {
        croakf 'Expected stage #%d to be a code reference', $n
            unless is_coderef($stages[$n - 1]);
    }
    return bless {
        stages => \@stages,
        call   => sub (@values) {
            return @values unless @stages;
            my $next = _iterator(\@stages, sub { @values ? shift @values : () });
            my @results;
            while (my($result) = $next->()) { push @results, $result }
            return @results;
        },
    }, $class;
}

# Return a closure handing out, one per call, the values from $source run
# through the stages.
sub iterator ($self, $source) {
    croakf 'Expected a code reference' unless is_coderef($source);
    return _iterator($self->{stages}, $source);
}

# Return a closure handing out, one per call, the values from $source run
# through the stages in @$stages.
sub _iterator ($stages, $source) {
    my @stages = @$stages;

    # Each value waiting to go through a stage, as the stage's index and
    # the value, the next on top. A value a stage returns on its own, as
    # most are, carries on through the stages without waiting here.
    my(@todo, $done);
    return sub () {
        while (1) {
            my($n, $value);
            if (@todo) {
                ($n, $value) = @{ pop @todo };
            }
            else {
                last if $done;
                my @values = $source->();
                unless (@values) {
                    $done = 1;
                    last;
                }
                ($n, $value) = (0, shift @values);
                push @todo, map { [0, $_] } reverse @values;
            }
            return $value if $n == @stages;
            my $kept = 1;
            try {
                while ($n < @stages) {
                    local $_ = $value;
                    my @values = $stages[$n]->($value);
                    $n++;
                    unless (@values) {
                        $kept = 0;
                        last;
                    }
                    $value = shift @values;
                    push @todo, map { [$n, $_] } reverse @values;
                }
            }
            catch ($e) {
                if ($e isa 'DBIx::Squirrel::Stop') {
                    my(undef, @values) = @$e;
                    $done = 1;
                    @todo = map { [$n + 1, $_] } reverse @values;
                    next;
                }
                croak $e if is_ref($e);
                my $at      = Carp::shortmess() =~ s( \.? \n \z )()xr;
                my $message = $e =~ s( \n \z )()xr =~ s( ^ )(    )xmgr;
                die "Pipeline stage #@{[ $n + 1 ]} failed$at:\n$message\n";
            }
            return $value if $kept;
        }
        return;
    };
}

1;
__END__

=encoding utf8

=for stopwords flatMap

=head1 NAME

DBIx::Squirrel::Pipeline - run values through a list of stages

=head1 SYNOPSIS

    use DBIx::Squirrel::Pipeline;

    my $p = DBIx::Squirrel::Pipeline->new(
        sub { $_->{active} ? $_ : () },          # filter
        sub ($row) { @{ $row->{tags} } },        # flatMap
        sub { uc },                              # map
    );

    # Push: values in, a list out
    my @tags = $p->(@rows);

    # Pull: one value per call, from a source
    my $next = $p->iterator(sub { $sth->fetchrow_hashref // () });
    while (my($tag) = $next->()) { ... }

=head1 DESCRIPTION

A pipeline is a list of stages, each a code reference. A stage is
called with one value, as its argument and in C<$_>, so it can name the
value with a signature, C<sub ($row) { $row-E<gt>[1] }>, or leave the
signature out and use C<$_>, C<sub { $_-E<gt>[1] }>. C<$_> is localised for
each call, so the caller's is left as it was. A stage returns a list:

=over

=item * nothing, to drop the value (a filter);

=item * one value, to pass it on (a map);

=item * several, each of which goes through the rest of the stages
on its own (a flatMap).

=back

Each value goes through every stage before the next one starts, so the
values come out in order, and a stage sees them in the order a C<for>
loop would.

A stage can end the pipeline early with L<DBIx::Squirrel::Stop>. The
values already out are kept, any values the stop carries go on through
the rest of the stages, and nothing else is processed:

    sub ($row) { $row->{id} == $wanted ? Stop($row) : () }

=head1 METHODS

=head2 new

    my $p = DBIx::Squirrel::Pipeline->new(@stages);

Returns a pipeline running values through C<@stages>, in order. It
croaks if a stage isn't a code reference. With no stages, a pipeline
returns its values as they are.

A pipeline is an object that can be called as a code reference. Called
with values, it returns the list that comes out of the last stage:

    my @results = $p->(@values);

=head2 iterator

    my $next = $p->iterator($source);

Returns a closure handing out, one per call, the values that come out
of the stages. C<$source> is a code reference returning the next value
or values on each call, and an empty list when there are no more; it's
called only when the values from its last call have all been handed
out.

The closure returns an empty list when the values run out, or once a
stage has stopped the pipeline and the values its stop carried are
handed out, and on every call after that. After a stop, the source
isn't called again. Read it in list context, so an C<undef> value
isn't mistaken as the end:

    while (my($x) = $next->()) { ... }

=head1 DIAGNOSTICS

=over

=item Expected stage #%d to be a code reference

A stage given to L</new> wasn't a code reference.

=item Expected a code reference

The source given to L</iterator> wasn't a code reference.

=item Pipeline stage #%d failed at %s line %d:

A stage died. The message it died with follows, indented. An exception
object is passed on as it is.

=back

=head1 SEE ALSO

L<DBIx::Squirrel>, L<DBIx::Squirrel::Stop>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
