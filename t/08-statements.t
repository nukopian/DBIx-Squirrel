use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel::Helpers qw(statement_study statement_trim);

subtest 'statement_trim' => sub {
    is statement_trim("  SELECT 1  "), 'SELECT 1', 'blank space around';
    is statement_trim("SELECT 1 -- one\nFROM t"), "SELECT 1\nFROM t",
        'a comment';
    is statement_trim("\n  SELECT 1\n  FROM t\n"), "SELECT 1\nFROM t",
        'each line';
    is statement_trim(" \n\t "),   '', 'all blank';
    is statement_trim(' -- only'), '', 'only a comment';
    is statement_trim(undef),      '', 'undef';
};

subtest 'statement_study, in each placeholder style' => sub {
    for my $p (qw(? ?1 :1 $1 :id)) {
        my($placeholders, $normalised, $trimmed)
            = statement_study("  SELECT * FROM t WHERE id = $p ");
        is $normalised, 'SELECT * FROM t WHERE id = ?',  "$p normalised";
        is $trimmed,    "SELECT * FROM t WHERE id = $p", "$p trimmed";
        is $placeholders, ($p eq '?' ? {} : {1 => $p}), "$p mapped";
    }
};

subtest 'statement_study numbers placeholders by position' => sub {
    my($placeholders, $normalised) = statement_study('SELECT :a, $2, :a, ?1');
    is $normalised, 'SELECT ?, ?, ?, ?', 'normalised';
    is $placeholders, {1 => ':a', 2 => '$2', 3 => ':a', 4 => '?1'},
        'every one, repeats included';
};

subtest 'statement_study of a blank statement' => sub {
    is [statement_study('  ')],  [], 'returns nothing';
    is [statement_study(undef)], [], 'nor for undef';
};

done_testing;
