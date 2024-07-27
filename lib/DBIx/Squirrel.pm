package DBIx::Squirrel;
use strict;
use warnings;

BEGIN {
    our $VERSION               = '1.0.0_210925';
    our @ISA                   = 'DBI';
    our $STRICT_PARAM_CHECKS   = 0;
    our $AUTO_FINISH_ON_ACTIVE = 1;
}

use DBI                ();
use DBIx::Squirrel::dr ();
use DBIx::Squirrel::db ();
use DBIx::Squirrel::st ();
use DBIx::Squirrel::it ();
use DBIx::Squirrel::rs ();
use DBIx::Squirrel::rc ();

BEGIN {
    our $NORMALISE_SQL = 1;

    *err             = *DBI::err;
    *errstr          = *DBI::errstr;
    *rows            = *DBI::rows;
    *lasth           = *DBI::lasth;
    *state           = *DBI::state;
    *connect_cached  = *DBIx::Squirrel::dr::connect_cached;
    *connect         = *DBIx::Squirrel::dr::connect;
    *SQL_ABSTRACT    = *DBIx::Squirrel::db::SQL_ABSTRACT;
    *DEFAULT_SLICE   = *DBIx::Squirrel::it::DEFAULT_SLICE;
    *DEFAULT_MAXROWS = *DBIx::Squirrel::it::DEFAULT_MAXROWS;
    *BUF_MULT        = *DBIx::Squirrel::it::BUF_MULT;
    *BUF_MAXROWS     = *DBIx::Squirrel::it::BUF_MAXROWS;
    *NORMALIZE_SQL   = *NORMALISE_SQL;
}

1;
