package                                                                                                                            # hide from PAUSE
  DBIx::Squirrel::dr;
use strict;
use warnings;

BEGIN {
    require DBIx::Squirrel
      unless defined $DBIx::Squirrel::VERSION;
    our $VERSION = $DBIx::Squirrel::VERSION;
    our @ISA     = 'DBI::dr';
}

{
    ( my $r = __PACKAGE__ ) =~ s/::\w+$//;

    sub ROOT_CLASS {
        return $r unless wantarray;
        return RootClass => $r;
    }
}

sub connect {
    return &connect_clone if UNIVERSAL::isa( $_[1], 'DBI::db' );
    return shift->DBI::connect(
          ( @_ && UNIVERSAL::isa( $_[$#_], 'HASH' ) )
        ? ( @_[ 0 .. $#_ - 1 ], { %{ $_[$#_] }, __PACKAGE__->ROOT_CLASS } )
        : ( @_, { __PACKAGE__->ROOT_CLASS } )
    );
}

sub connect_cached {
    return shift->DBI::connect_cached(
          ( @_ && UNIVERSAL::isa( $_[$#_], 'HASH' ) )
        ? ( @_[ 0 .. $#_ - 1 ], { %{ $_[$#_] }, __PACKAGE__->ROOT_CLASS } )
        : ( @_, { __PACKAGE__->ROOT_CLASS } )
    );
}

sub connect_clone {
    return unless UNIVERSAL::isa( $_[1], 'DBI::db' );
    return $_[1]->clone(
          ( @_ && UNIVERSAL::isa( $_[$#_], 'HASH' ) )
        ? ( { %{ $_[$#_] }, __PACKAGE__->ROOT_CLASS } )
        : ( { __PACKAGE__->ROOT_CLASS } )
    );
}

1;
