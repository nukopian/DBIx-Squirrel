use strict 'vars', 'subs';  # Moved to stop Perl::Critic carping when Dist::Zilla adds
                            # $VERSION information.

package DBIx::Squirrel;

use warnings;
use constant E_BAD_ENT_BIND     => 'Cannot associate with an invalid object';
use constant E_EXP_HASH_ARR_REF => 'Expected a reference to a HASH or ARRAY';

use Scalar::Util 'reftype';
use Sub::Name;

=pod

=encoding UTF-8

=head1 NAME

DBIx::Squirrel - A module for working with databases

=head1 SYNOPSIS

    # Simply use the package.

    use DBIx::Squirrel;

    $dbh = DBIx::Squirrel->connect($dsn, $user, $pass, \%attr);
    $sth = $dbh->prepare('SELECT * FROM product WHERE id = ?');
    $res = $sth->execute('1001099');
    $itr = $sth->iterate('1001099');
    while ($row = $itr->next) {...}

    # Or, use it and have it create and import helper functions that you
    # can define at runtime use (and reuse) to interact with database
    # connections, statements and iterators.

    use DBIx::Squirrel 'db', 'st', 'it';

    db DBIx::Squirrel->connect($dsn, $user, $pass, \%attr);
    st db->prepare('SELECT * FROM product WHERE id = ?');
    $res = st->execute('1001099');
    $res = st('1001099');  # Same as line above.
    it st->iterate('1001099');
    while ($row = it->next) {...}

    # Clone another database connection.

    $dbi = DBI->connect($dsn, $user, $pass, \%attr);
    $dbh = DBIx::Squirrel->connect($dbi);

    # Prepare a statement object.

    $sth = $dbh->prepare($statement, \%attr);
    $sth = $dbh->prepare_cached($statement, \%attr, $if_active);

    # Commonly used positional and named parameter placeholder schemes
    # conveniently supported regardless of database driver in use.

    $sth = $dbh->prepare('SELECT * FROM product WHERE id = ?');
    $sth = $dbh->prepare('SELECT * FROM product WHERE id = ?1');
    $sth = $dbh->prepare('SELECT * FROM product WHERE id = $1');
    $sth = $dbh->prepare('SELECT * FROM product WHERE id = :1');
    $sth = $dbh->prepare('SELECT * FROM product WHERE id = :id');

    # Able to bind values to individual parameters for both positional
    # and named placeholder schemes.

    $sth->bind_param(1, '1001099');
    $sth->bind_param(':id', '1001099');
    $sth->bind_param('id', '1001099');

    # Bind multiple values to parameters in a single statement.

    $sth->bind( '1001099', ... );
    $sth->bind( [ '1001099', ... ] );
    $sth->bind( ':id' => '1001099', ... );
    $sth->bind( id => '1001099', ... );
    $sth->bind( { ':id' => '1001099', ... } );
    $sth->bind( { id => '1001099', ... } );

    # Or just have the statement handle's or iterator's "execute"
    # method bind all values to parameters by passing it the same
    # arguments you would pass to "bind".

    $res = $obj->execute( '1001099', ... );
    $res = $obj->execute( [ '1001099', ... ] );
    $res = $obj->execute( ':id' => '1001099', ... );
    $res = $obj->execute( id => '1001099', ... );
    $res = $obj->execute( { ':id' => '1001099', ... } );
    $res = $obj->execute( { id => '1001099', ... } );

    # The database handle "do" method works as it does with DBI,
    # with the exception that returns the result followed by the
    # statement handle when called in list-context. This means
    # we can use it to prepare and execute statements, before we
    # fetch results. Be careful to use "undef" if passing named
    # parameters in a hashref so they are not used as statement
    # attributes. The new "do" is smart enough not to confuse
    # other things as statement attributes.

    ($res, $sth) = $dbh->do(
        'SELECT * FROM product WHERE id = ?', '1001099'
    );
    ($res, $sth) = $dbh->do(
        'SELECT * FROM product WHERE id = ?', ['1001099']
    );
    ($res, $sth) = $dbh->do(
        'SELECT * FROM product WHERE id = :id', ':id' => '1001099'
    );
    ($res, $sth) = $dbh->do(
        'SELECT * FROM product WHERE id = :id', id => '1001099'
    );
    ($res, $sth) = $dbh->do( # ------------ undef or \%attr
        'SELECT * FROM product WHERE id = :id', undef,
        { ':id' => '1001099'}
    );
    ($res, $sth) = $dbh->do( # ------------ undef or \%attr
        'SELECT * FROM product WHERE id = :id', undef,
        { id => '1001099' },
    );

    # Statement objects can create iterators using the "iterate"
    # method (or its "it" alias). Use it as you would "execute"

    $itr = $sth->iterate( '1001099' );
    $itr = $sth->iterate(['1001099']);

    $itr = $sth->iterate( '1001099' );
    $itr = $sth->iterate(['1001099']);

    $itr = $sth->iterate( '1001099' );
    $itr = $sth->iterate(['1001099']);

    $itr = $sth->iterate( '1001099' );
    $itr = $sth->iterate(['1001099']);

    $itr = $sth->iterate( '1001099' );
    $itr = $sth->iterate(['1001099']);

    $itr = $sth->iterate( ':id' => '1001099' );
    $itr = $sth->iterate( id => '1001099' );

    $itr = $sth->iterate( { ':id' => '1001099' } );
    $itr = $sth->iterate( { id => '1001099' } );

    # Using the iterators couldn't be easier!

    @ary = ();
    while ($row = $itr->next) {
        push @ary, $row;
    }

    @ary = $itr->first;
    push @ary, $_ while $itr->next;

    @ary = $itr->first;
    push @ary, $itr->remaining;

    @ary = $itr->all;

    $itr = $itr->reset;     # Repositions iterator at the start
    $itr = $itr->reset({}); # Fetch rows as hashrefs
    $itr = $itr->reset([]); # Fetch rows as arrayrefs

    $row = $itr->single;
    $row = $itr->single( id => '1001100' );
    $row = $itr->single( { id => '1001100' } );
    $row = $itr->find( id => '1001100' );
    $row = $itr->find( { id => '1001100' } );

    # A result set is just fancy subclass of the iterator. It will
    # "bless" results, enabling us to get a column's value using an
    # accessor methods, without ever having to worry about whether
    # the row is a array or hash reference. While the accessor
    # methods use lowercase names, they will access the column's
    # value regardless of the case used.

    $sth = $dbh->prepare('SELECT MediaTypeId, Name FROM media_types');
    $res = $sth->rs;
    while ($res->next) {
        print $_->name, "\n";
    }

    # Iterators allow for the use of lambda functions to process
    # each row just in time during iteration.

    $it = $sth->iterate(
        sub { $_->{Name} }
    )->reset({});
    print "$_\n" foreach $it->all;

    # Lambdas may be chained.

    $res = $sth->rs(
        sub { $_->Name },
        sub { "Media type: $_" },
    );
    print "$_\n" while $res->next;

    print "$_\n" for $dbh->rs(
        q/SELECT MediaTypeId, Name FROM media_types/,
        sub { $_->Name },
    )->all;

    print "$_\n" for $dbh->select('media_types')->rs(
        sub { $_->Name },
    )->all;

=cut

use DBI                ();
use DBIx::Squirrel::dr ();
use DBIx::Squirrel::db ();
use DBIx::Squirrel::st ();
use DBIx::Squirrel::it ();
use DBIx::Squirrel::rs ();
use DBIx::Squirrel::rc ();
use DBIx::Squirrel::util 'throw';

BEGIN {
    *err    = *DBI::err;
    *errstr = *DBI::errstr;
    *rows   = *DBI::rows;
    *lasth  = *DBI::lasth;
    *state  = *DBI::state;

    *connect         = *DBIx::Squirrel::dr::connect;
    *connect_cached  = *DBIx::Squirrel::dr::connect_cached;
    *SQL_ABSTRACT    = *DBIx::Squirrel::db::SQL_ABSTRACT;
    *DEFAULT_SLICE   = *DBIx::Squirrel::it::DEFAULT_SLICE;
    *DEFAULT_MAXROWS = *DBIx::Squirrel::it::DEFAULT_MAXROWS;
    *BUF_MULT        = *DBIx::Squirrel::it::BUF_MULT;
    *BUF_MAXROWS     = *DBIx::Squirrel::it::BUF_MAXROWS;

    our @ISA                   = ('DBI');
    our $STRICT_PARAM_CHECKING = 0;
    our $AUTO_FINISH_ON_ACTIVE = 1;
    our $NORMALISE_SQL         = 1;
    *NORMALIZE_SQL = *NORMALISE_SQL;
}

# By appending a list of one or more names to the caller's "use" directive,
# can have the DBIx::Squirrel package define helper functions ("helpers")
# during Perl's compile-phase. All listed helpers are exported to the
# caller's namespace. Any helper that has already been defined will only
# be exported; it will not be re-defined.
#
# A helper is a callable name that may be associated with a database
# object (connection, statement, iterator) during runtime. A helper acts
# as a shim, allowing the caller to get (or address) the underlying object
# without Perl's traditional line-noise ("$", "->", "(...)").
#
# Absent any arguments, a call to a helper simply returns the reference
# to the object itself. When called with arguments, a statement or
# iterator helper will behave as if a call was made to the underlying
# object's "execute" method. A database connection helper doesn't care
# what is passed; a reference to the connection is all that is returned.
#
# Since some statements do not require arguments, execution is coerced
# by passing a reference to an empty ARRAY or HASH. For the sake of
# consistency, a reference to an ARRAY or HASH containing arguments
# may also be passed.

sub import {
    my $class  = shift;
    my $caller = caller;

    my @helper_names = @_;

    for my $name (@helper_names) {
        my $symbol = $class . '::' . $name;

        # Define the symbol once only!

        unless ( defined &{$symbol} ) {
            *{$symbol} = subname(
                $symbol => sub {
                    if (@_) {

                        # No reason NOT to have helpers act as proxies for
                        # DBI connection and statement objects, too!

                        if (   UNIVERSAL::isa( $_[0], 'DBI::db' )
                            or UNIVERSAL::isa( $_[0], 'DBI::st' )
                            or UNIVERSAL::isa( $_[0], 'DBIx::Squirrel::it' ) )
                        {
                            ${$symbol} = shift;
                            return ${$symbol};
                        }

                        throw E_BAD_ENT_BIND;
                    }

                    # Return nothing if no association is defined!

                    return unless defined ${$symbol};

                    # If we have arguments remaining and an object we can
                    # meaningfully address, dispatch the "execute" method!

                    if (@_
                        and (  UNIVERSAL::isa( ${$symbol}, 'DBI::st' )
                            or UNIVERSAL::isa( ${$symbol}, 'DBIx::Squirrel::it' ) )
                      )
                    {
                        my @params = do {
                            if ( @_ == 1 && ref $_[0] ) {
                                if ( reftype( $_[0] ) eq 'ARRAY' ) {
                                    @{ +shift };
                                } elsif ( reftype( $_[0] ) eq 'HASH' ) {
                                    %{ +shift };
                                } else {
                                    throw E_EXP_HASH_ARR_REF;
                                }
                            } else {
                                @_;
                            }
                        };

                        return ${$symbol}->execute(@params);
                    }

                    # For any other situation, return a reference to the
                    # associated object!

                    return ${$symbol};
                }
            );
        }

        # Export any relevant symbols to caller's namespace.

        unless ( defined &{ $caller . '::' . $name } ) {
            *{ $caller . '::' . $name } = \&{$symbol};
        }
    }

    return $class;
}

# Provide a means for undefining and unexporting helpers.

sub unimport {
    my $class  = shift;
    my $caller = caller;

    my @helper_names = @_;

    for my $name (@helper_names) {
        my $symbol = $class . '::' . $name;

        undef &{$symbol} if defined &{$symbol};
        undef ${$symbol} if defined ${$symbol};
        undef &{ $caller . '::' . $name } if defined &{ $caller . '::' . $name };
    }

    return $class;
}

1;
__END__

=pod

=encoding UTF-8

=head1 DESCRIPTION

B<Just what the world needs — another Perl package for working with databases!>

C<DBIx::Squirrel> is a C<DBI> extension that serves as drop-in replacement for
C<DBI>, while adding a few progressive enhancements to make some tasks much
easier.

=head1 DESIGN

=head2 Compatibility

DBIx-Squirrel's baseline behaviour is be like C<DBI>.

A developer should be able to confidently replace C<use DBI> with
C<use DBIx::Squirrel>, while expecting their script to behave just
as it did before the change.

DBIx-Squirrel's enhancements are designed to be low-friction, intuitive, and
elective. Code using this package should behave like code using DBI, that is
until deviation from standard behaviour is expected and invited.

=head2 Ease of use

An experienced user of DBI, or someone familiar with DBI's documentation,
should be able to use DBIx-Squirrel without any issues.

DBIx-Squirrel's enhancements are either additive or progressive. Experienced
DBI and DBIx-Class programmers should find a cursory glance at the synopsis
enough to get started in next to no time at all.

The intention has been for DBIx-Squirrel was to occupy a sweet spot between DBI
and DBIx-Class (though much closer to DBI).

=head1 OVERVIEW

=head2 Connecting to databases, and preparing statements

=over

=item *

The C<connect> method continues to work as expected. It may also be invoked
with a single argument (another database handle), if the intention is to clone
that connection. This is particularly useful when cloning a standard DBI
database object, since the resulting clone will be a DBI-Squirrel
database object.

=item *

Both C<prepare> and C<prepare_cached> methods continue to work as expected,
though passing a statement handle, instead of a statement in a string, results
in that statement being cloned. Again, this is useful when the intention is to
clone a standard DBI statement object in order to produce a DBIx-Squirrel
statement object.

=back

=head2 Parameter placeholders, bind values, and iterators

=over

=item *

Regardless of the database driver being used, DBIx-Squirrel provides full,
baseline support for five parameter placeholder schemes (C<?>, C<?1>,
C<$1>, C<:1>, C<:name>), offering a small degree of code portability to
programmers with standard SQL, SQLite, PostgreSQL and Oracle backgrounds.

=item *

A statement object's C<bind_param> method will continue to work as expected,
though its behaviour has been progressively enhanced. It now accommodates
both C<bind_param(':name', 'value')> and C<bind_param('name', 'value')>
calling styles, as well as the C<bind_param(1, 'value')> style for
positional placeholders.

=item *

Statement objects have a new C<bind> method aimed at greatly streamlining
the binding of values to statement parameters.

=item *

A statement object's C<execute> method will accept any arguments you would
pass to the C<bind> method. It isn't really necessary to call C<bind> because
C<execute> will take care of that.

=item *

DBIx-Squirrel iterators make the traversal of result sets simple and
efficient, and these can be generated by using a statement object's
C<iterate> method in place of C<execute>, with both methods taking
the same arguments.

=item *

Some DBIx-Squirrel iterator method names (C<reset>, C<first>, C<next>,
C<single>, C<find>, C<all>) may be familiar to other DBIx-Class
programmers who use them for similar purposes.

=back

=head1 COPYRIGHT AND LICENSE

    The DBIx::Squirrel module is Copyright (c) 2020-2014 Iain Campbell.
    All rights reserved.

    You may distribute under the terms of either the GNU General Public
    License or the Artistic License, as specified in the Perl 5.10.0 README file.

=head1 SUPPORT / WARRANTY

DBIx::Squirrel is free Open Source software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=cut
