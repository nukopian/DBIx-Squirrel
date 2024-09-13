use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('Crypt::CBC');
    use_ok('Digest::SHA');
    use_ok('MIME::Base64::URLSafe');
    use_ok(
        'DBIx::Squirrel::Crypt::Fernet',
        qw/fernet_decrypt fernet_encrypt fernet_genkey fernet_verify Fernet/,
    );
}

diag(
    "Testing DBIx::Squirrel::Crypt::Fernet $DBIx::Squirrel::Crypt::Fernet::VERSION, Perl $], $^X"
);

{
    note("Function interface");

    my $key         = DBIx::Squirrel::Crypt::Fernet::generate_key();
    my $plaintext   = 'This is a test';
    my $token       = DBIx::Squirrel::Crypt::Fernet::encrypt($key, $plaintext);
    my $verify      = DBIx::Squirrel::Crypt::Fernet::verify($key, $token);
    my $decrypttext = DBIx::Squirrel::Crypt::Fernet::decrypt($key, $token);
    my $old_key     = 'cJ3Fw3ehXqef-Vqi-U8YDcJtz8Gv-ZHyxultoAGHi4c=';
    my $old_token
        = 'gAAAAABT8bVcdaked9SPOkuQ77KsfkcoG9GvuU4SVWuMa3ewrxpQdreLdCT6cc7rdqkavhyLgqZC41dW2vwZJAHLYllwBmjgdQ==';

    my $ttl = 10;
    my $old_verify
        = DBIx::Squirrel::Crypt::Fernet::verify($old_key, $old_token, $ttl);
    my $old_decrypttext
        = DBIx::Squirrel::Crypt::Fernet::decrypt($old_key, $old_token, $ttl);
    my $ttl_verify = DBIx::Squirrel::Crypt::Fernet::verify($key, $token, $ttl);
    my $ttl_decrypttext
        = DBIx::Squirrel::Crypt::Fernet::decrypt($key, $token, $ttl);

    ok($key);
    ok($token);
    ok($verify);
    ok($decrypttext eq $plaintext);
    ok($old_verify == 0);
    ok(!defined $old_decrypttext);
    ok($ttl_verify);
    ok($ttl_decrypttext eq $plaintext);
}

{
    note("Object-oriented interface");

    my $key         = Fernet->generate_key();
    my $fernet      = Fernet($key);
    my $plaintext   = 'This is a test';
    my $token       = $fernet->encrypt($plaintext);
    my $verify      = $fernet->verify($token);
    my $decrypttext = $fernet->decrypt($token);
    my $old_key     = 'cJ3Fw3ehXqef-Vqi-U8YDcJtz8Gv-ZHyxultoAGHi4c=';
    my $old_token
        = 'gAAAAABT8bVcdaked9SPOkuQ77KsfkcoG9GvuU4SVWuMa3ewrxpQdreLdCT6cc7rdqkavhyLgqZC41dW2vwZJAHLYllwBmjgdQ==';
    my $ttl             = 10;
    my $old_verify      = Fernet($old_key)->verify($old_token, $ttl);
    my $old_decrypttext = Fernet($old_key)->decrypt($old_token, $ttl);
    my $ttl_verify      = Fernet($key)->verify($token, $ttl);
    my $ttl_decrypttext = Fernet($key)->decrypt($token, $ttl);

    ok($key);
    ok($token);
    ok($verify);
    ok($decrypttext eq $plaintext);
    ok($old_verify == 0);
    ok(!defined $old_decrypttext);
    ok($ttl_verify);
    ok($ttl_decrypttext eq $plaintext);
}

done_testing();
