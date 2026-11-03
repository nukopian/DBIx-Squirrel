use v5.36;
use utf8;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel::Placeholders qw(study_sql trim_sql);

subtest 'trim_sql' => sub {
    is trim_sql("  SELECT 1  "), 'SELECT 1', 'blank space around';
    is trim_sql("SELECT 1 -- one\nFROM t"), "SELECT 1 -- one\nFROM t",
        'keeps a comment';
    is trim_sql("\n  SELECT 1\n  FROM t\n"), "SELECT 1\n  FROM t",
        'keeps the blank space inside';
    is trim_sql(" \n\t "),   '',        'all blank';
    is trim_sql(' -- only'), '-- only', 'keeps a lone comment';
    is trim_sql(undef),      '',        'undef';
};

subtest 'study_sql, in each placeholder style' => sub {
    for my $p (qw(? ?1 :1 $1 :id)) {
        my($placeholders, $normalised, $trimmed)
            = study_sql("  SELECT * FROM t WHERE id = $p ");
        is $normalised, 'SELECT * FROM t WHERE id = ?',  "$p normalised";
        is $trimmed,    "SELECT * FROM t WHERE id = $p", "$p trimmed";
        is $placeholders, {1 => $p}, "$p mapped";
    }
};

subtest 'study_sql numbers placeholders by position' => sub {
    my($placeholders, $normalised) = study_sql('SELECT :a, $2, :a, ?1');
    is $normalised, 'SELECT ?, ?, ?, ?', 'normalised';
    is $placeholders, {1 => ':a', 2 => '$2', 3 => ':a', 4 => '?1'},
        'every one, repeats included';

    ($placeholders, $normalised) = study_sql('SELECT ?, :a, ?');
    is $normalised, 'SELECT ?, ?, ?', 'mixed with bare ?, normalised';
    is $placeholders, {1 => '?', 2 => ':a', 3 => '?'},
        'mixed with bare ?, counting each';
};

subtest 'study_sql leaves alone what only looks like one' => sub {
    my @unchanged = (
        q{SELECT x::int},                      # a PostgreSQL cast
        q{SELECT * FROM v$session},            # an Oracle view
        q{SELECT '10:30', 'it''s :x'},         # strings
        q{SELECT "a:b", `c?`},                 # quoted identifiers
        qq{SELECT 1 -- :x\n},                  # a line comment
        q{SELECT 1 /* $1 ? :x */},             # a block comment
        q{SELECT $$ :x ? $$, $fn$ $1 $fn$},    # dollar-quoted bodies
    );
    for my $statement (@unchanged) {
        my($placeholders, $normalised) = study_sql($statement);
        is $normalised, trim_sql($statement), "unchanged: $statement";
        is $placeholders, {}, "none found: $statement";
    }
};

subtest 'study_sql finds placeholders beside them' => sub {
    my($placeholders, $normalised)
        = study_sql(
            q{SELECT x::int, '10:30' /* :y */ FROM t WHERE a = :a AND b = ?AND});
    is $normalised,
        q{SELECT x::int, '10:30' /* :y */ FROM t WHERE a = ? AND b = ?AND},
        'normalised';
    is $placeholders, {1 => ':a', 2 => '?'},
        'a ? touching a keyword is a bare ?';
    ($placeholders, $normalised) = study_sql('SELECT :naïve');
    is $placeholders, {1 => ':naïve'}, 'a name is taken whole';
};

# Each case: the driver, the statement, the statement as normalised, and
# the placeholders found. ":no" is never a placeholder.
my @dialects = (
    [
        'standard rules: a backslash ends nothing',
        undef, q{SELECT 'C:\', :x}, q{SELECT 'C:\', ?}, {1 => ':x'},
    ],
    [
        'doubled quotes',
        'Pg', q{SELECT 'it''s :no', '''', ':no''', :x},
        q{SELECT 'it''s :no', '''', ':no''', ?}, {1 => ':x'},
    ],
    [
        'an E string takes backslashes and doubled quotes',
        'Pg', q{SELECT E'a''b\' :no', e'\\', :x},
        q{SELECT E'a''b\' :no', e'\\', ?}, {1 => ':x'},
    ],
    [
        'a backslash before a sigil, for DBD::Pg',
        'Pg', q{SELECT d \? 'k', d \?| a, d \?& a, \:no, \$1, :x},
        q{SELECT d \? 'k', d \?| a, d \?& a, \:no, \$1, ?}, {1 => ':x'},
    ],
    [
        '# is not a comment, but an operator',
        'Pg', q{SELECT a # :x}, q{SELECT a # ?}, {1 => ':x'},
    ],
    [
        'MySQL: a backslash escapes a quote',
        'mysql', q{SELECT 'it\'s :no', :x}, q{SELECT 'it\'s :no', ?},
        {1 => ':x'},
    ],
    [
        'MySQL: "..." is a string, taking backslashes',
        'mysql', q{SELECT "say \"hi :no\"", :x},
        q{SELECT "say \"hi :no\"", ?}, {1 => ':x'},
    ],
    [
        'MySQL: # starts a comment',
        'mysql', qq{SELECT :x # :no\n, :y}, qq{SELECT ? # :no\n, ?},
        {1 => ':x', 2 => ':y'},
    ],
    [
        'MariaDB: the same as MySQL',
        'MariaDB', q{SELECT 'it\'s :no', :x}, q{SELECT 'it\'s :no', ?},
        {1 => ':x'},
    ],
);

subtest 'study_sql in each dialect' => sub {
    for my $case (@dialects) {
        my($name, $driver, $statement, $want, $want_placeholders) = @$case;
        my($placeholders, $normalised) = study_sql($statement, $driver);
        is $normalised,   $want,              "$name: normalised";
        is $placeholders, $want_placeholders, "$name: placeholders";
    }
};

subtest 'study_sql of a blank statement' => sub {
    is [study_sql('  ')],  [], 'returns nothing';
    is [study_sql(undef)], [], 'nor for undef';
};

done_testing;
