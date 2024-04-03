package DBIx::Squirrel;
use strict;
use warnings;

BEGIN {
    our $VERSION               = '1.20210925';
    our @ISA                   = 'DBI';
    our $RELAXED_PARAM_CHECKS  = 0;
    our $AUTO_FINISH_ON_ACTIVE = 1;
}

use DBI ();
use DBIx::Squirrel::dr ();
use DBIx::Squirrel::db ();
use DBIx::Squirrel::st ();
use DBIx::Squirrel::it ();
use DBIx::Squirrel::rs ();
use DBIx::Squirrel::rc ();

BEGIN {
    *err             = *DBI::err;
    *errstr          = *DBI::errstr;
    *rows            = *DBI::rows;
    *lasth           = *DBI::lasth;
    *state           = *DBI::state;
    *connect_cached  = *DBIx::Squirrel::dr::connect_cached;
    *connect         = *DBIx::Squirrel::dr::connect;
    *connect_clone   = *DBIx::Squirrel::dr::connect_clone;
    *SQL_ABSTRACT    = *DBIx::Squirrel::db::SQL_ABSTRACT;
    *DEFAULT_SLICE   = *DBIx::Squirrel::it::DEFAULT_SLICE;
    *DEFAULT_MAXROWS = *DBIx::Squirrel::it::DEFAULT_MAXROWS;
    *BUF_MULT        = *DBIx::Squirrel::it::BUF_MULT;
    *BUF_MAXROWS     = *DBIx::Squirrel::it::BUF_MAXROWS;
    *NORMALISE_SQL   = *DBIx::Squirrel::db::NORMALISE_SQL;
    *NORMALIZE_SQL   = *DBIx::Squirrel::db::NORMALISE_SQL;
    *HASH            = *DBIx::Squirrel::util::HASH;
}

1;

__END__


=pod

=encoding UTF-8

=head1 PROJECT STATUS

B<Code works, but this project is not yet finished>

Documentation far from complete. Test coverage is ok but far from finished.

=head1 NAME

DBIx::Squirrel - A module for working with databases

=head1 VERSION

2020.11.00

=head1 SYNOPSIS

    use DBIx::Squirrel;

    $db1 = DBI->connect($dsn, $user, $pass, \%attr);
    $dbh = DBIx::Squirrel->connect($db1);
    $dbh = DBIx::Squirrel->connect($dsn, $user, $pass, \%attr);

    $st1 = $db1->prepare('SELECT * FROM product WHERE id = ?');
    $sth = $dbh->prepare($st1);
    $sth->bind_param(1, '1001099');
    $sth->bind( '1001099' );
    $sth->bind(['1001099']);
    $res = $sth->execute;
    $res = $sth->execute( '1001099' );
    $res = $sth->execute(['1001099']);
    $itr = $sth->it( '1001099' );
    $itr = $sth->it(['1001099']);

    $sth = $dbh->prepare('SELECT * FROM product WHERE id = ?');
    $sth->bind_param(1, '1001099');
    $sth->bind( '1001099' );
    $sth->bind(['1001099']);
    $res = $sth->execute;
    $res = $sth->execute( '1001099' );
    $res = $sth->execute(['1001099']);
    $itr = $sth->it( '1001099' );
    $itr = $sth->it(['1001099']);

    $sth = $dbh->prepare('SELECT * FROM product WHERE id = ?1');
    $sth->bind_param(1, '1001099');
    $sth->bind( '1001099' );
    $sth->bind(['1001099']);
    $res = $sth->execute;
    $res = $sth->execute( '1001099' );
    $res = $sth->execute(['1001099']);
    $itr = $sth->it( '1001099' );
    $itr = $sth->it(['1001099']);

    $sth = $dbh->prepare('SELECT * FROM product WHERE id = $1');
    $sth->bind_param(1, '1001099');
    $sth->bind( '1001099' );
    $sth->bind(['1001099']);
    $res = $sth->execute;
    $res = $sth->execute( '1001099' );
    $res = $sth->execute(['1001099']);
    $itr = $sth->it( '1001099' );
    $itr = $sth->it(['1001099']);

    $sth = $dbh->prepare('SELECT * FROM product WHERE id = :1');
    $sth->bind_param(1, '1001099');
    $sth->bind( '1001099' );
    $sth->bind(['1001099']);
    $res = $sth->execute;
    $res = $sth->execute( '1001099' );
    $res = $sth->execute(['1001099']);
    $itr = $sth->it( '1001099' );
    $itr = $sth->it(['1001099']);

    $sth = $dbh->prepare('SELECT * FROM product WHERE id = :id');
    $sth->bind_param(':id', '1001099');
    $res = $sth->bind( ':id'=>'1001099' );
    $res = $sth->bind([':id'=>'1001099']);
    $res = $sth->bind({':id'=>'1001099'});
    $res = $sth->bind( id=>'1001099' );
    $res = $sth->bind([id=>'1001099']);
    $res = $sth->bind({id=>'1001099'});
    $res = $sth->execute;
    $res = $sth->execute( id=>'1001099' );
    $res = $sth->execute([id=>'1001099']);
    $res = $sth->execute({id=>'1001099'});
    $itr = $sth->it( id=>'1001099' );
    $itr = $sth->it([id=>'1001099']);
    $itr = $sth->it({id=>'1001099'});

    # The database handle "do" method works as before, but it also
    # returns the statement handle when called in list-context. So
    # we can use it to prepare and execute statements, before we
    # fetch results. Be careful to use "undef" if passing named
    # parameters in a hashref so they are not used as statement
    # attributes. The new "do" is smart enough not to confuse
    # other things as statement attributes.
    #
    ($res, $sth) = $dbh->do(
        'SELECT * FROM product WHERE id = ?', '1001099'
    );
    ($res, $sth) = $dbh->do(
        'SELECT * FROM product WHERE id = ?', ['1001099']
    );
    ($res, $sth) = $dbh->do(
        'SELECT * FROM product WHERE id = :id', ':id'=>'1001099'
    );
    ($res, $sth) = $dbh->do(
        'SELECT * FROM product WHERE id = :id', id=>'1001099'
    );
    ($res, $sth) = $dbh->do(
        'SELECT * FROM product WHERE id = :id', [':id'=>'1001099']
    );
    ($res, $sth) = $dbh->do(
       'SELECT * FROM product WHERE id = :id', [id=>'1001099']
    );
    ($res, $sth) = $dbh->do( # ------------ undef or \%attr
        'SELECT * FROM product WHERE id = :id', undef,
        {':id'=>'1001099'}
    );
    ($res, $sth) = $dbh->do( # ------------ undef or \%attr
        'SELECT * FROM product WHERE id = :id', undef,
        {id=>'1001099'},
    );

    # Using the iterators couldn't be easier!
    #
    @ary = ();
    while ($next = $itr->next) {
        push @ary, $next;
    }

    @ary = $itr->head;
    push @ary, $_ while $itr->next;

    @ary = $itr->head;
    push @ary, $itr->tail;

    @ary = $itr->all;

    $itr = $itr->reset;     # Repositions iterator at the start
    $itr = $itr->reset({}); # Fetch rows as hashrefs
    $itr = $itr->reset([]); # Fetch rows as arrayrefs

    $row = $itr->single;
    $row = $itr->single( id=>'1001100' );
    $row = $itr->single([id=>'1001100']);
    $row = $itr->single({id=>'1001100'});
    $row = $itr->find( id=>'1001100' );
    $row = $itr->find([id=>'1001100']);
    $row = $itr->find({id=>'1001100'});

    # Result sets are just fancy iterators that "bless" results in
    # a manner that enables us to get column values using accessor
    # methods, without ever having to worry about whether the row
    # is implemented as an arrayref or hashref. Accessors are not
    # case-sensitive.
    #
    $sth = $dbh->prepare('SELECT MediaTypeId, Name FROM media_types');
    $res = $sth->rs;
    while ($res->next) {
        print $_->name, "\n";
    }

    # Use lambdas to define how results are processed.
    #
    $it = $sth->it(
        sub { $_->{Name} }
    )->reset({});
    print "$_\n" foreach $it->all;

    # Lambdas may be chained
    #
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

=head1 DESCRIPTION

Just what the world needs — another Perl module for working with databases.

DBIx-Squirrel is a DBI extension that subclasses packages in the DBI namespace,
to add a few enhancements to its venerable ancestor's interface.

=head1 DESIGN

=head2 Compatibility

DBIx-Squirrel's baseline behaviour is B<be like DBI>.

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

=head1 AUTHOR

Nukopia Software Services

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Nukopia Software Services.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
