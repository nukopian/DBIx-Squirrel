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
            'E_EXP_STATEMENT',
            'E_EXP_STH',
            'E_EXP_REF',
        ],
        'diagnostics' => [
            'Dumper',
            'throw',
            'whine',
        ],
        'transform' => [
            'cbargs',
            'cbargs_using',
            'transform',
        ],
        'sql' => [
            'get_trimmed_sql_and_digest',
            'normalise_statement',
            'study_statement',
            'trim_sql_string',
            'hash_sql_string',
        ]
    );
    our @EXPORT_OK = @{
        $EXPORT_TAGS{'all'} = [
            do {
                my %seen;
                grep { !$seen{$_}++ } map { @{ $EXPORT_TAGS{$_} } } (
                    'constants',
                    'diagnostics',
                    'sql',
                    'transform',
                );
            }
        ]
    };
}

use Carp ();
use Data::Dumper::Concise;
use Digest::SHA 'sha256_base64';
use Memoize;
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

sub study_statement {
    my ( $normalised_sql_string, $sql_string, $sql_digest ) = &normalise_statement;
    return unless defined $sql_string;
    my @placeholders = $sql_string =~ m{[\:\$\?]\w+\b}g;
    return undef, $normalised_sql_string, $sql_string, $sql_digest unless @placeholders;
    my %placeholder_position_mappings = map { ( 1 + $_ => $placeholders[$_] ) } ( 0 .. @placeholders - 1 );
    return \%placeholder_position_mappings, $normalised_sql_string, $sql_string, $sql_digest;
}

BEGIN { memoize('study_statement'); }

sub normalise_statement {
    my ( $sql_string, $sql_digest ) = &get_trimmed_sql_and_digest;
    my $normalised_sql_string = $sql_string;
    if ($DBIx::Squirrel::NORMALISE_SQL) {
        $normalised_sql_string =~ s{[\:\$\?]\w+\b}{?}g;
    }
    return $normalised_sql_string unless wantarray;
    return $normalised_sql_string, $sql_string, $sql_digest;

}

sub get_trimmed_sql_and_digest {
    my $sth_or_sql_string = shift;
    my $sql_string        = do {
        if ( ref $sth_or_sql_string ) {
            if ( UNIVERSAL::isa( $sth_or_sql_string, 'DBIx::Squirrel::st' ) ) {
                trim_sql_string( $sth_or_sql_string->_attr->{'OriginalStatement'} );
            } elsif ( UNIVERSAL::isa( $sth_or_sql_string, 'DBI::st' ) ) {
                trim_sql_string( $sth_or_sql_string->{Statement} );
            } else {
                throw E_EXP_STH;
            }
        } else {
            trim_sql_string($sth_or_sql_string);
        }
    };
    return $sql_string unless wantarray;
    my $sql_digest = hash_sql_string($sql_string);
    return $sql_string, $sql_digest;
}

sub trim_sql_string {
    my $sql_string = shift;
    return '' unless defined $sql_string && length $sql_string && $sql_string =~ m/\S/;
    (   s{\s+-{2}\s+.*$}{}gm,
        s{^[[:blank:]\r\n]+}{}gm,
        s{[[:blank:]\r\n]+$}{}gm,
    ) for $sql_string;
    return $sql_string;
}

BEGIN { memoize('trim_sql_string'); }

sub hash_sql_string {
    my $sql_string = shift;
    return unless defined $sql_string && length $sql_string && $sql_string =~ m/\S/;
    return sha256_base64($sql_string);
}

BEGIN { memoize('hash_sql_string'); }

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
                @_;
            } elsif ( UNIVERSAL::isa( $_[0], 'CODE' ) ) {
                [shift], @_;
            } else {
                throw E_BAD_CB_LIST;
            }
        } else {
            shift;
            [], @_;
        }
    };
    unshift @{$c}, pop @t while UNIVERSAL::isa( $t[$#t], 'CODE' );
    return $c, @t;
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
    my @transforms = do {
        if ( UNIVERSAL::isa( $_[0], 'ARRAY' ) ) {
            @{ +shift };
        } elsif ( UNIVERSAL::isa( $_[0], 'CODE' ) ) {
            shift;
        } else {
            ();
        }
    };
    if ( @transforms && @_ ) {
        local ($_);
        for my $transform (@transforms) {
            last unless @_ = do {
                ($_) = @_;
                $transform->(@_);
            };
        }
    }
    return @_        if wantarray;
    return scalar @_ if @_ > 1;
    return $_[0];
}

1;
