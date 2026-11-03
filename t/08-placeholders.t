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

subtest 'study_sql of a blank statement' => sub {
    is [study_sql('  ')],  [], 'returns nothing';
    is [study_sql(undef)], [], 'nor for undef';
};

done_testing;
