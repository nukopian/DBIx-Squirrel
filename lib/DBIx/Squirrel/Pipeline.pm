use v5.36;

package DBIx::Squirrel::Pipeline;

use experimental qw(try);

use Carp      qw(croak);
use Ref::Util qw(is_coderef);

use namespace::clean;

use overload '&{}' => sub ($self, @) { $self->{call} }, fallback => 1;

our @CARP_NOT = qw(DBIx::Squirrel DBIx::Squirrel::Pipes);

# Return a pipeline, called with values to run each of them through the
# stages.
sub new ($class, @stages) {
    for my $n (1 .. @stages) {
        croak "Stage #$n is not a code-reference"
            unless is_coderef($stages[$n - 1]);
    }
    return bless {
        stages => \@stages,
        call   => sub (@xs) {
            return @xs unless @stages;
            my $next = _iterator(\@stages, sub { @xs ? shift @xs : () });
            my @ys;
            while (my($y) = $next->()) { push @ys, $y }
            return @ys;
        },
    }, $class;
}

# Return a closure handing out, one per call, the values from $source run
# through the stages.
sub iterator ($self, $source) {
    croak "Expected a code-reference" unless is_coderef($source);
    return _iterator($self->{stages}, $source);
}

# Return a closure handing out, one per call, the values from $source run
# through the stages in @$stages.
sub _iterator ($stages, $source) {
    my @p = @$stages;
    my(@todo, $done);
    return sub () {
        while (1) {
            unless (@todo) {
                last if $done;
                my @xs = $source->();
                unless (@xs) {
                    $done = 1;
                    last;
                }
                push @todo, map { [0, $_] } reverse @xs;
            }
            my($s, $x) = @{ pop @todo };
            return $x if $s == @p;
            try {
                local $_ = $x;
                push @todo, map { [$s + 1, $_] } reverse $p[$s]->($x);
            }
            catch ($e) {
                if ($e isa 'DBIx::Squirrel::Stop') {
                    my(undef, @values) = @$e;
                    $done = 1;
                    @todo = map { [$s + 1, $_] } reverse @values;
                    next;
                }
                croak $e if ref $e;
                my $at = Carp::shortmess() =~ s/\.?\n\z//xr;
                my $err = $e =~ s/\n\z//xr =~ s/^/    /xmgr;
                die "Pipeline stage #@{[ $s + 1 ]} failed$at:\n$err\n";
            }
        }
        return;
    };
}

1;
__END__

=encoding utf8

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
called with one value, as its argument and in C<$_>, and returns a
list:

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

    my @ys = $p->(@xs);

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

=item Stage #%d is not a code-reference

A stage given to L</new> wasn't a code reference.

=item Expected a code-reference

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

Copyright (c) 2024 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
