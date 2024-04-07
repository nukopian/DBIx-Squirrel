BEGIN {
    delete $INC{'FindBin.pm'};
    require FindBin;
}

use Test::Most;
use Capture::Tiny (
    'capture_merged',
    'capture_stdout',
    'capture_stderr',
    'capture',
    'tee_merged',
    'tee_stdout',
    'tee_stderr',
    'tee'
);
use Cwd 'realpath';
use DBI;
use DBIx::Squirrel::util (':all');
use DBIx::Squirrel;

use lib realpath("$FindBin::Bin/../lib");
use T::Database ':all';

our ( $stdout, $stderr, $merged );
our ( $res,    @res );
our ( $got,    $exp );
our ( @arr,    %hash );
our ( $aref,   $href );
our ( $cref,   $crefs );
our (@args);

subtest 'DBIx::Squirrel::db::_sqltrim' => sub {
    my $hash_of = \%DBIx::Squirrel::util::_HASH_OF;

    is( DBIx::Squirrel::db::_sqltrim("  \n\t  SELECT * FROM t  \n  "), 'SELECT * FROM t' );
    is_deeply(
        [ DBIx::Squirrel::db::_sqltrim("  \n\t  SELECT * FROM t  \n  ") ],
        [
            'SELECT * FROM t',
            $hash_of->{'SELECT * FROM t'}
        ]
    );

    my $dbi_dbh = DBI->connect(@T_DB_CONNECT_ARGS);
    my $dbi_sth = $dbi_dbh->prepare("  SELECT * FROM media_types  ");
    is_deeply(
        [ DBIx::Squirrel::db::_sqltrim($dbi_sth) ],
        [
            'SELECT * FROM media_types',
            $hash_of->{'SELECT * FROM media_types'}
        ]
    );
    $dbi_dbh->disconnect;

    my $ekorn_dbh = DBIx::Squirrel->connect(@T_DB_CONNECT_ARGS);
    my $ekorn_sth = $ekorn_dbh->prepare("  SELECT COUNT(*) FROM media_types  ");
    is_deeply(
        [ DBIx::Squirrel::db::_sqltrim($ekorn_sth) ],
        [
            'SELECT COUNT(*) FROM media_types',
            $hash_of->{'SELECT COUNT(*) FROM media_types'}
        ]
    );
    $ekorn_dbh->disconnect;
};

subtest 'DBIx::Squirrel::db::_sqlnorm' => sub {
    my $hash_of = \%DBIx::Squirrel::util::_HASH_OF;

    undef $DBIx::Squirrel::db::NORMALISE_SQL;

    is(
        DBIx::Squirrel::db::_sqlnorm('   SELECT * FROM media_types WHERE MediatypeId = ?   '),
        'SELECT * FROM media_types WHERE MediatypeId = ?',
    );
    is(
        DBIx::Squirrel::db::_sqlnorm('   SELECT * FROM media_types WHERE MediatypeId = ?1   '),
        'SELECT * FROM media_types WHERE MediatypeId = ?1',
    );
    is(
        DBIx::Squirrel::db::_sqlnorm('   SELECT * FROM media_types WHERE MediatypeId = $1   '),
        'SELECT * FROM media_types WHERE MediatypeId = $1',
    );
    is(
        DBIx::Squirrel::db::_sqlnorm('   SELECT * FROM media_types WHERE MediatypeId = :1   '),
        'SELECT * FROM media_types WHERE MediatypeId = :1',
    );
    is(
        DBIx::Squirrel::db::_sqlnorm('   SELECT * FROM media_types WHERE MediatypeId = :id   '),
        'SELECT * FROM media_types WHERE MediatypeId = :id',
    );
    is_deeply(
        [ DBIx::Squirrel::db::_sqlnorm('   SELECT * FROM media_types WHERE MediatypeId = ?   ') ],
        [
            'SELECT * FROM media_types WHERE MediatypeId = ?',
            'SELECT * FROM media_types WHERE MediatypeId = ?',
            $hash_of->{'SELECT * FROM media_types WHERE MediatypeId = ?'},
        ]
    );
    is_deeply(
        [ DBIx::Squirrel::db::_sqlnorm('   SELECT * FROM media_types WHERE MediatypeId = ?1   ') ],
        [
            'SELECT * FROM media_types WHERE MediatypeId = ?1',
            'SELECT * FROM media_types WHERE MediatypeId = ?1',
            $hash_of->{'SELECT * FROM media_types WHERE MediatypeId = ?1'},
        ]
    );
    is_deeply(
        [ DBIx::Squirrel::db::_sqlnorm('   SELECT * FROM media_types WHERE MediatypeId = $1   ') ],
        [
            'SELECT * FROM media_types WHERE MediatypeId = $1',
            'SELECT * FROM media_types WHERE MediatypeId = $1',
            $hash_of->{'SELECT * FROM media_types WHERE MediatypeId = $1'},
        ]
    );
    is_deeply(
        [ DBIx::Squirrel::db::_sqlnorm('   SELECT * FROM media_types WHERE MediatypeId = :1   ') ],
        [
            'SELECT * FROM media_types WHERE MediatypeId = :1',
            'SELECT * FROM media_types WHERE MediatypeId = :1',
            $hash_of->{'SELECT * FROM media_types WHERE MediatypeId = :1'},
        ]
    );
    is_deeply(
        [ DBIx::Squirrel::db::_sqlnorm('   SELECT * FROM media_types WHERE MediatypeId = :id   ') ],
        [
            'SELECT * FROM media_types WHERE MediatypeId = :id',
            'SELECT * FROM media_types WHERE MediatypeId = :id',
            $hash_of->{'SELECT * FROM media_types WHERE MediatypeId = :id'},
        ]
    );

    $DBIx::Squirrel::db::NORMALISE_SQL = 1;

    is(
        DBIx::Squirrel::db::_sqlnorm('   SELECT * FROM media_types WHERE MediatypeId = ? AND Name = ?   '),
        'SELECT * FROM media_types WHERE MediatypeId = ? AND Name = ?',
    );
    is(
        DBIx::Squirrel::db::_sqlnorm('   SELECT * FROM media_types WHERE MediatypeId = ?1 AND Name = ?2   '),
        'SELECT * FROM media_types WHERE MediatypeId = ? AND Name = ?',
    );
    is(
        DBIx::Squirrel::db::_sqlnorm('   SELECT * FROM media_types WHERE MediatypeId = $1 AND Name = $2   '),
        'SELECT * FROM media_types WHERE MediatypeId = ? AND Name = ?',
    );
    is(
        DBIx::Squirrel::db::_sqlnorm('   SELECT * FROM media_types WHERE MediatypeId = :1 AND Name = :2   '),
        'SELECT * FROM media_types WHERE MediatypeId = ? AND Name = ?',
    );
    is(
        DBIx::Squirrel::db::_sqlnorm('   SELECT * FROM media_types WHERE MediatypeId = :id AND Name = :name   '),
        'SELECT * FROM media_types WHERE MediatypeId = ? AND Name = ?',
        $hash_of->{'SELECT * FROM media_types WHERE MediatypeId = ? AND Name = ?'},
    );
    is_deeply(
        [ DBIx::Squirrel::db::_sqlnorm('   SELECT * FROM media_types WHERE MediatypeId = ? AND Name = ?   ') ],
        [
            'SELECT * FROM media_types WHERE MediatypeId = ? AND Name = ?',
            'SELECT * FROM media_types WHERE MediatypeId = ? AND Name = ?',
            $hash_of->{'SELECT * FROM media_types WHERE MediatypeId = ? AND Name = ?'},
        ]
    );
    is_deeply(
        [ DBIx::Squirrel::db::_sqlnorm('   SELECT * FROM media_types WHERE MediatypeId = ?1 AND Name = ?2   ') ],
        [
            'SELECT * FROM media_types WHERE MediatypeId = ? AND Name = ?',
            'SELECT * FROM media_types WHERE MediatypeId = ?1 AND Name = ?2',
            $hash_of->{'SELECT * FROM media_types WHERE MediatypeId = ?1 AND Name = ?2'},
        ]
    );
    is_deeply(
        [ DBIx::Squirrel::db::_sqlnorm('   SELECT * FROM media_types WHERE MediatypeId = $1 AND Name = $2   ') ],
        [
            'SELECT * FROM media_types WHERE MediatypeId = ? AND Name = ?',
            'SELECT * FROM media_types WHERE MediatypeId = $1 AND Name = $2',
            $hash_of->{'SELECT * FROM media_types WHERE MediatypeId = $1 AND Name = $2'},
        ]
    );
    is_deeply(
        [ DBIx::Squirrel::db::_sqlnorm('   SELECT * FROM media_types WHERE MediatypeId = :1 AND Name = :2   ') ],
        [
            'SELECT * FROM media_types WHERE MediatypeId = ? AND Name = ?',
            'SELECT * FROM media_types WHERE MediatypeId = :1 AND Name = :2',
            $hash_of->{'SELECT * FROM media_types WHERE MediatypeId = :1 AND Name = :2'},
        ]
    );
    is_deeply(
        [ DBIx::Squirrel::db::_sqlnorm('   SELECT * FROM media_types WHERE MediatypeId = :id AND Name = :name   ') ],
        [
            'SELECT * FROM media_types WHERE MediatypeId = ? AND Name = ?',
            'SELECT * FROM media_types WHERE MediatypeId = :id AND Name = :name',
            $hash_of->{'SELECT * FROM media_types WHERE MediatypeId = :id AND Name = :name'},
        ]
    );
};

subtest 'hashing' => sub {
    my $_SHA256_B64        = $DBIx::Squirrel::util::_SHA256_B64;
    my $_MIME_B64          = $DBIx::Squirrel::util::_MIME_B64;
    my $hash_of           = \%DBIx::Squirrel::util::_HASH_OF;
    my $hash_with         = \%DBIx::Squirrel::util::_HASH_WITH;
    my $hash_strategies_a = \@DBIx::Squirrel::util::_HASH_STRATEGIES;
    my $hash_strategies_h = \%DBIx::Squirrel::util::_HASH_STRATEGIES;

    is hash('Foo'), $hash_strategies_a->[0][1]->('Foo');
    is unhash( hash('Foo') ), 'Foo';

    SKIP: {
        undef %DBIx::Squirrel::util::_HASH_OF;
        undef %DBIx::Squirrel::util::_HASH_WITH;
        skip 'Skipping tests', 3 unless $_SHA256_B64;

        my $h = $_SHA256_B64->('Foo');
        is $h, 'HL7HN/hj5JIs7mPMLrv6r80c/4t5DYz9LmpdVQtkivo';
        is $hash_of->{'Foo'}, $h;
        is $hash_with->{ $hash_of->{'Foo'} }, 'Foo';
    }

    SKIP: {
        undef %DBIx::Squirrel::util::_HASH_OF;
        undef %DBIx::Squirrel::util::_HASH_WITH;

        skip 'Skipping tests', 3 unless $_MIME_B64;

        my $h = $_MIME_B64->( 'Foo', 1 );
        is $h, 'Rm9v';
        is $hash_of->{'Foo'}, $h;
        is $hash_with->{ $hash_of->{'Foo'} }, 'Foo';
    }
};

subtest 'cbargs' => sub {
    %hash = (
        'sub1' => sub { 1 },
        'sub2' => sub { 2 },
    );

    is_deeply( [ cbargs( 1 .. 5 ) ], [ [], 1 .. 5 ] );

    is_deeply(
        [ cbargs( 1 .. 5, $hash{'sub1'} ) ],
        [ [ $hash{'sub1'} ], 1 .. 5 ]
    );

    is_deeply(
        [ cbargs( 1 .. 5, $hash{'sub1'}, $hash{'sub2'} ) ],
        [ [ $hash{'sub1'}, $hash{'sub2'}, ], 1 .. 5 ]
    );
};

subtest 'cbargs_using' => sub {
    %hash = (
        'sub1' => sub { 1 },
        'sub2' => sub { 2 },
    );

    is_deeply( [ cbargs_using( undef, 1 .. 5 ) ], [ [], 1 .. 5 ] );

    is_deeply( [ cbargs_using( [], 1 .. 5 ) ], [ [], 1 .. 5 ] );

    is_deeply(
        [ cbargs_using( [], 1 .. 5, $hash{'sub1'} ) ],
        [ [ $hash{'sub1'} ], 1 .. 5 ]
    );

    is_deeply(
        [ cbargs_using( [], 1 .. 5, $hash{'sub1'}, $hash{'sub2'} ) ],
        [ [ $hash{'sub1'}, $hash{'sub2'}, ], 1 .. 5 ]
    );

    is_deeply(
        [ cbargs_using( [ $hash{'sub2'} ], 1 .. 5, $hash{'sub1'}, ) ],
        [ [ $hash{'sub1'}, $hash{'sub2'}, ], 1 .. 5 ]
    );
};

subtest 'transform' => sub {
    is_deeply( [ transform() ], [] );

    is_deeply( [ transform( [] ) ], [] );

    is_deeply( [ transform( [], 99 ) ], [99] );

    is_deeply( [ transform( [], 98, 99 ) ], [ 98, 99 ] );

    is_deeply(
        [ transform( sub { $_ + 1 }, 99 ) ],
        [100]
    );

    is_deeply(
        [ transform( sub { $_[0] + 1 }, 99 ) ],
        [100]
    );

    is_deeply(
        [ transform( [ sub { $_ + 1 } ], 99 ) ],
        [100]
    );

    is_deeply(
        [ transform( [ sub { $_[0] + 1 } ], 99 ) ],
        [100]
    );

    is_deeply(
        [
            transform(
                [
                    sub {
                        map { $_ + 1 } @_;
                    }
                ],
                98,
                99
            )
        ],
        [ 99, 100 ]
    );

    is_deeply(
        [
            transform(
                [
                    sub { $_ + 1 },
                    sub { $_ - 2 }
                ],
                99
            )
        ],
        [98]
    );

    is_deeply(
        [
            transform(
                [
                    sub { $_[0] + 1 },
                    sub { $_[0] - 2 }
                ],
                99
            )
        ],
        [98]
    );

    is_deeply(
        [
            transform(
                [
                    sub {
                        map { $_ + 1 } @_;
                    },
                    sub {
                        map { $_ - 2 } @_;
                    },
                ],
                98,
                99
            )
        ],
        [ 97, 98 ]
    );
};

subtest 'throw' => sub {
    eval { throw undef };
    like( $@, qr/\AException at / );

    eval { throw 'Got an exception' };
    like( $@, qr/\AGot an exception at / );

    eval { throw 'Exception %d, %d, %d', 1, 2, 3 };
    like( $@, qr/\AException 1, 2, 3 at/ );

    eval {
        $@ = 'Rethrow this';
        throw;
    };
    like( $@, qr/\ARethrow this at/ );
};

subtest 'whine' => sub {
    $stderr = capture_stderr { whine undef };
    like( $stderr, qr/\AWarning at / );

    $stderr = capture_stderr { whine 'Got a warning' };
    like( $stderr, qr/\AGot a warning at / );

    $stderr = capture_stderr { whine 'Warning %d, %d, %d', 1, 2, 3 };
    like( $stderr, qr/\AWarning 1, 2, 3 at/ );

    $stderr = capture_stderr { whine };
    like( $stderr, qr/\AWarning at/ );
};

ok 1, __FILE__ . ' complete';
done_testing;
