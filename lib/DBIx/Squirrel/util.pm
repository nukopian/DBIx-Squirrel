package                                                                                                                            # hide from PAUSE
  DBIx::Squirrel::util;
use strict;
use warnings;
use constant E_EXP_STATEMENT => 'Expected a statement';
use constant E_EXP_STH       => 'Expected a statement handle';
use constant E_EXP_REF       => 'Expected a reference to a HASH or ARRAY';
use constant E_BAD_CB_LIST   => 'Expected a reference to a list of code-references, a code-reference, or undefined';

BEGIN {
    require Exporter;
    our @ISA         = 'Exporter';
    our %EXPORT_TAGS = (
        'constants' => [
            qw/
              E_EXP_STATEMENT
              E_EXP_STH
              E_EXP_REF
              /
        ],
        'hashing' => [
            qw/
              hash
              unhash
              $HASH
              /
        ],
        'sql' => [
            qw/
              hash
              unhash
              _sqlnorm
              _study
              _sqltrim
              /
        ],
        'transform' => [
            qw/
              cbargs
              cbargs_using
              cbargs_using_nr
              transform
              /
        ],
        'diagnostics' => [
            qw/
              Dumper
              throw
              whine
              /
        ],
    );
    our @EXPORT_OK = @{
        $EXPORT_TAGS{ 'all' } = [
            do {
                my %seen;
                grep { !$seen{ $_ }++ } map { @{ $EXPORT_TAGS{ $_ } } } (
                    'constants',
                    'hashing',
                    'sql',
                    'transform',
                    'diagnostics',
                );
            }
        ]
    };
}

use Carp ();
use Data::Dumper::Concise;
use Digest::SHA 'sha256_base64';
use Scalar::Util ();
use Sub::Name    ();

sub throw {
    @_ = do {
        if (@_) {
            my ( $f, @a ) = @_;
            if (@a) {
                sprintf $f, @a;
            } else {
                defined $f ? $f : 'Exception';
            }
        } ## end if ( @_ )
        else {
            defined $@ ? $@ : 'Exception';
        }
    };
    goto &Carp::confess;
}

sub whine {
    @_ = do {
        if (@_) {
            my ( $f, @a ) = @_;
            if (@a) {
                sprintf $f, @a;
            } else {
                defined $f ? $f : 'Warning';
            }
        } ## end if ( @_ )
        else {
            'Warning';
        }
    };
    goto &Carp::cluck;
}

our $HASH;
our $_SHA256_B64;
our $_MIME_B64;
our %_HASH_OF;
our %_HASH_WITH;
our $_HASH_STRATEGY;
our @_HASH_STRATEGIES;
our %_HASH_STRATEGIES;

BEGIN {
    $_SHA256_B64 = eval {
                sub {
            return unless defined $_[0];
            my ( $st, $bool ) = @_;
            unless ( exists $_HASH_OF{$st} && !$bool ) {
                $_HASH_OF{$st} = sha256_base64($st);
                $_HASH_WITH{ $_HASH_OF{$st} } = $st;
            }
            return $_HASH_OF{$st};
        };
    };

    %_HASH_STRATEGIES = map { $_->[0] => $_->[1] } (
        @_HASH_STRATEGIES = grep { !!$_->[1] } (
            [ '_SHA256_B64', $_SHA256_B64 ],
            )
    );

    $_HASH_STRATEGY = $_HASH_STRATEGIES[0][0];
        $HASH           = $_HASH_STRATEGIES[0][1];
        
    sub hash { goto &{$HASH} }

    sub unhash {
        return unless defined $_[0];
        return exists $_HASH_WITH{ $_[0] } ? $_HASH_WITH{ $_[0] } : $_[0];
    }
}

# Separates any trailing code-references ("callbacks") from other arguments,
# partitioning each type into its own distinct collection.
#
#   (c, a...) = cbargs(t...)
#
#   Arguments:
#
#   t - The arguments to be partitioned, expressed as a flat list.
#
#   Returns a list containing two elements:
#
#   c - A partition containing only the contiguous code-references located
#       at the end of the list (t), and expressed as a reference to a list of
#       code-references.
#   a - A partition containing all arguments that are not part of list (C),
#       in the same order as they were presented in list (t), expressed as
#       a flat list.
#
# Example
#
#   sub my_callback_enabled_fn {
#       ($callbacks, @_) = cbargs(@_);
#       ...
#   }
#
sub cbargs {
    return cbargs_using( [], @_ );
}

# Separates any trailing code-references ("callbacks") from other arguments,
# partitioning each type into its own distinct collection. This function
# differs from "cbargs" in that the initial state of the callback queue is
# determined at the call-site.
#
#   (c, a...) = cbargs_using(c, t...)
#
#   Arguments:
#
#   c - The initial state of the partition that will contain all of the
#       callbacks. This is typically undefined, or a reference to an empty
#       list. If undefined, a reference to an empty list will be used. If a
#       reference to a pre-populated list is passed, any new callbacks will
#       be _prepended_ to the supplied list.
#   t - The arguments to be partitioned, expressed as a flat list.
#
#   Returns a list containing two elements:
#
#   c - A partition containing only the contiguous code-references located
#       at the end of the list (t), and expressed as a reference to a list of
#       code-references.
#   a - A partition containing all arguments that are not part of list (C),
#       in the same order as they were presented in list (t), expressed as
#       a flat list.
#
# Example
#
#   sub my_callback_enabled_fn {
#       ($callbacks, @_) = cbargs_using([], @_);
#       ...
#   }
#
sub cbargs_using {
    my ( $c, @t ) = do {
        if ( defined $_[0] ) {
            if ( UNIVERSAL::isa( $_[0], 'ARRAY' ) ) {
                ( $_[0], @_[ 1 .. $#_ ] );
            } else {
                throw E_BAD_CB_LIST
                  unless UNIVERSAL::isa( $_[0], 'CODE' );
                ( [ $_[0] ], @_[ 1 .. $#_ ] );
            }
        } ## end if ( defined $_[ 0 ] )
        else {
            ( [], @_[ 1 .. $#_ ] );
        }
    };
    while ( UNIVERSAL::isa( $t[$#t], 'CODE' ) ) {
        unshift @{$c}, pop @t;
    }
    return ( $c, @t );
}

# Apply one or more transformations ("callbacks") to a scalar value, or
# to a list of values.
#
#   v = transform(c, v...)
#
#   Arguments:
#
#   v - The starting value to be transformed, expressed as a list of one or
#       more scalars.
#   c - The transformations to apply to the value, expressed as a single
#       code-reference, or as a reference to a list of code-references.
#
#   Returns:
#
#   v - The transformed value, expressed as a list, when called in list
#       context, or as a scalar when called in scalar context. In scalar
#       context, a transformation resulting in a list containing only one
#       element returns that element rather than the length of the list.
#
# Example
#
#   sub my_callback_enabled_fn {
#       ($callbacks, @_) = cbargs_using([], @_);
#       my @res = ...
#       return transform($callbacks, @res);
#   }
#
sub transform {
    return unless my @v = @_[ 1 .. $#_ ];
    my $c
      = UNIVERSAL::isa( $_[0], 'ARRAY' ) ? $_[0]
      : UNIVERSAL::isa( $_[0], 'CODE' )  ? [ $_[0] ]
      :                                    undef;
    if ( $c && @{$c} ) {
        local ($_);
        for my $t ( @{$c} ) {
            last unless @v = do { ($_) = @v; $t->(@v) };
        }
    }
    return wantarray ? @v : @v == 1 ? $v[0] : @v;
}

1;
