package DBIx::Squirrel;

# ABSTRACT: The little Perl DBI extension that makes working with databases a lot easier.

use 5.010_001;
use strict;
use warnings;
use DBI;
use Exporter;
use Scalar::Util qw/reftype/;
use Sub::Name;
use DBIx::Squirrel::dr          ();
use DBIx::Squirrel::db          ();
use DBIx::Squirrel::st          ();
use DBIx::Squirrel::Iterator    ();
use DBIx::Squirrel::ResultSet   ();
use DBIx::Squirrel::ResultClass ();
use DBIx::Squirrel::util        qw/throw/;
use namespace::clean;

BEGIN {
    @DBIx::Squirrel::ISA            = qw/DBI/;
    $DBIx::Squirrel::VERSION        = "1.005_005";
    $DBIx::Squirrel::VERSION        = eval($DBIx::Squirrel::VERSION);        ## no critic
    @DBIx::Squirrel::EXPORT_OK      = @DBI::EXPORT_OK;
    %DBIx::Squirrel::EXPORT_TAGS    = %DBI::EXPORT_TAGS;
    *DBIx::Squirrel::err            = *DBI::err;
    *DBIx::Squirrel::errstr         = *DBI::errstr;
    *DBIx::Squirrel::rows           = *DBI::rows;
    *DBIx::Squirrel::lasth          = *DBI::lasth;
    *DBIx::Squirrel::state          = *DBI::state;
    *DBIx::Squirrel::connect        = *DBIx::Squirrel::dr::connect;
    *DBIx::Squirrel::connect_cached = *DBIx::Squirrel::dr::connect_cached;
    *DBIx::Squirrel::FINISH_ACTIVE_BEFORE_EXECUTE
        = *DBIx::Squirrel::st::FINISH_ACTIVE_BEFORE_EXECUTE;
    *DBIx::Squirrel::DEFAULT_SLICE = *DBIx::Squirrel::Iterator::DEFAULT_SLICE;
    *DBIx::Squirrel::DEFAULT_CACHE_SIZE
        = *DBIx::Squirrel::Iterator::DEFAULT_CACHE_SIZE;
    *DBIx::Squirrel::CACHE_SIZE_LIMIT = *DBIx::Squirrel::Iterator::CACHE_SIZE_LIMIT;
}

use constant E_BAD_ENT_BIND     => 'Cannot associate with an invalid object';
use constant E_EXP_HASH_ARR_REF => 'Expected a reference to a HASH or ARRAY';

# Divide the argumments into two lists:
# 1. a list of helper function names;
# 2. a list of names to be imported from the DBI.
sub _partition_imports_into_helpers_and_dbi_imports {
    my(@helpers, @dbi);
    while (@_) {
        next unless defined($_[0]);
        if ($_[0] =~ m/^database_entit(?:y|ies)$/i) {
            shift;
            if (ref($_[0])) {
                if (UNIVERSAL::isa($_[0], 'ARRAY')) {
                    push @helpers, @{+shift};
                }
                else {
                    shift;
                }
            }
            else {
                push @helpers, shift();
            }
        }
        else {
            push @dbi, shift();
        }
    }
    return (\@helpers, \@dbi);
}

sub import {
    no strict 'refs';    ## no critic
    my $class  = shift;
    my $caller = caller;
    my($helpers, $dbi) = _partition_imports_into_helpers_and_dbi_imports(@_);
    for my $name (@{$helpers}) {
        my $symbol = $class . '::' . $name;
        my $helper = sub {
            if (@_) {
                if (   UNIVERSAL::isa($_[0], 'DBI::db')
                    or UNIVERSAL::isa($_[0], 'DBI::st')
                    or UNIVERSAL::isa($_[0], 'DBIx::Squirrel::Iterator'))
                {
                    ${$symbol} = shift;
                    return ${$symbol};
                }
            }
            return unless defined(${$symbol});
            if (@_) {
                my @params = do {
                    if (@_ == 1 && ref $_[0]) {
                        if (reftype($_[0]) eq 'ARRAY') {
                            @{+shift};
                        }
                        elsif (reftype($_[0]) eq 'HASH') {
                            %{+shift};
                        }
                        else {
                            throw E_EXP_HASH_ARR_REF;
                        }
                    }
                    else {
                        @_;
                    }
                };
                if (UNIVERSAL::isa(${$symbol}, 'DBI::db')) {
                    return ${$symbol}->prepare(@params);
                }
                elsif (UNIVERSAL::isa(${$symbol}, 'DBI::st')) {
                    return ${$symbol}->execute(@params);
                }
                elsif (UNIVERSAL::isa(${$symbol}, 'DBIx::Squirrel::Iterator')) {
                    return ${$symbol}->iterate(@params);
                }
                else {
                    # ok - no worries
                }
            }
            return ${$symbol};
        };
        *{$symbol} = subname($name => $helper);
        *{$caller . '::' . $name} = subname($caller . '::' . $name => \&{$symbol})
            unless defined(&{$caller . '::' . $name});
    }
    if (@{$dbi}) {
        DBI->import(@{$dbi});
        @_ = ('DBIx::Squirrel', @{$dbi});
        goto &Exporter::import;
    }
    return $class;
}

1;
