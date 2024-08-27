use 5.010_001;
use strict;
use warnings;

package    # hide from PAUSE
  DBIx::Squirrel::util;

use Carp                     ();
use Devel::GlobalDestruction ();
use Digest::SHA              qw/sha256_base64/;
use Memoize;
use Scalar::Util;
use Sub::Name;

BEGIN {
    require Exporter;
    @DBIx::Squirrel::util::ISA       = qw/Exporter/;
    @DBIx::Squirrel::util::EXPORT_OK = (
        qw/
          E_EXP_REF
          E_EXP_STATEMENT
          E_EXP_STH
          args_partition
          global_destruct_phase
          result
          statement_digest
          statement_normalise
          statement_study
          statement_trim
          throw
          whine
          /
    );
    %DBIx::Squirrel::util::EXPORT_TAGS = (all => [@DBIx::Squirrel::util::EXPORT_OK]);
}

use constant E_EXP_STATEMENT => 'Expected a statement';
use constant E_EXP_STH       => 'Expected a statement handle';
use constant E_EXP_REF       => 'Expected a reference to a HASH or ARRAY';
use constant E_BAD_CB_LIST   => 'Expected a reference to a list of code-references, a code-reference, or undefined';

sub args_partition {
    my $s = @_;
    return [] unless $s;
    my $n = $s;
    while ($n) {
        last unless UNIVERSAL::isa($_[$n - 1], 'CODE');
        $n -= 1;
    }
    return [@_] if $n == 0;
    return [], @_ if $n == $s;
    return [@_[$n .. $#_]], @_[0 .. $n - 1];
}

# Perl versions older than 5.14 do not support ${^GLOBAL_PHASE}, so provide
# a shim that works around that wrinkle.
sub global_destruct_phase {Devel::GlobalDestruction::in_global_destruction()}

memoize('statement_digest');

sub statement_digest {sha256_base64(shift)}

sub statement_normalise {
    my $trimmed = statement_trim(@_);
    my $normal  = $trimmed;
    $normal =~ s{[\:\$\?]\w+\b}{?}g;
    return $normal, $trimmed, statement_digest($trimmed);
}

#TODO These statement functions really need moving!
sub statement_study {
    local($_);
    my($normal, $trimmed, $digest) = statement_normalise(@_);
    return unless length($trimmed);
    my %positions_to_params_map = do {
        if (my @params = $trimmed =~ m{[\:\$\?]\w+\b}g) {
            map {(1 + $_ => $params[$_])} 0 .. $#params;
        }
        else {
            ();
        }
    };
    return \%positions_to_params_map, $normal, $trimmed, $digest;
}

sub statement_trim {
    my $sql = do {
        if (ref($_[0])) {
            if (UNIVERSAL::isa($_[0], 'DBIx::Squirrel::st')) {
                shift->_private_state->{OriginalStatement};
            }
            elsif (UNIVERSAL::isa($_[0], 'DBI::st')) {
                shift->{Statement};
            }
            else {
                throw(E_EXP_STH);
            }
        }
        else {
            defined($_[0]) ? shift : '';
        }
    };
    $sql        =~ s{\s+--\s+.*$}{}gm;
    $sql        =~ s{^[[:blank:]\r\n]+}{}gm;
    $sql        =~ s{[[:blank:]\r\n]+$}{}gm;
    return $sql =~ m/\S/ ? $sql : '';
}

sub throw {
    Carp::confess do {
        if (@_) {
            my($f, @a) = @_;
            @a ? sprintf($f, @a) : $f || $@ || 'Unknown exception thrown';
        }
        else {
            $@ || 'Unknown exception thrown';
        }
    };
}

sub whine {
    Carp::cluck do {
        if (@_) {
            my($f, @a) = @_;
            @a ? sprintf($f, @a) : $f || 'Unhelpful warning issued';
        }
        else {
            'Unhelpful warning issued';
        }
    };
}

1;
