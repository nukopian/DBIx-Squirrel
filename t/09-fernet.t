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

diag join " " => (
    "Testing DBIx::Squirrel::Crypt::Fernet",
    $DBIx::Squirrel::Crypt::Fernet::VERSION,
    ", Perl $], $^X",
);

my($expired_key, $expired_token) = (
    'cJ3Fw3ehXqef-Vqi-U8YDcJtz8Gv-ZHyxultoAGHi4c=',
    'gAAAAABT8bVcdaked9SPOkuQ77KsfkcoG9GvuU4SVWuMa3ewrxpQdreLdCT6cc7rdqkavhyLgqZC41dW2vwZJAHLYllwBmjgdQ==',
);

{
    note $_ for "", "Testing legacy exported interface", "";

    my $key = fernet_genkey();
    ok($key, "got key $key");

    my $plaintext = 'This is a test';
    my $token     = fernet_encrypt($key, $plaintext);
    ok($token, "got token $token");

    my $verify = fernet_verify($key, $token);
    ok($verify, "good verify");

    my $decrypttext = fernet_decrypt($key, $token);
    is($decrypttext, $plaintext, "good decrypt");

    my $ttl            = 10;
    my $expired_verify = fernet_verify($expired_key, $expired_token, $ttl);
    ok(!$expired_verify, "bad expired verify (as expected)");

    my $expired_decrypttext = fernet_decrypt($expired_key, $expired_token, $ttl);
    is($expired_decrypttext, undef, "bad expired decrypt (as expected)");

    my $ttl_verify = fernet_verify($key, $token, $ttl);
    ok($ttl_verify, "good unexpired verify");

    my $ttl_decrypttext = fernet_decrypt($key, $token, $ttl);
    is($ttl_decrypttext, $plaintext, "good unexpired decrypt");
}

{
    note $_ for "", "Testing object-oriented interface", "";

    my $b64_key = Fernet->generatekey();
    ok($b64_key, "got key $b64_key");

    my $fernet = Fernet($b64_key);
    isa_ok($fernet, 'DBIx::Squirrel::Crypt::Fernet');

    my $key = urlsafe_b64decode($b64_key);
    is($fernet->{key}, $key, "object contains decoded key $b64_key");

    my $plaintext = 'This is a test';
    my $token     = $fernet->encrypt($plaintext);
    ok($token, "got valid token $token");

    my $verify = $fernet->verify($token);
    ok($verify, "good verify");

    my $decrypttext = $fernet->decrypt($token);
    is($decrypttext, $plaintext, "good decrypt");

    my $ttl            = 10;
    my $expired_verify = Fernet($expired_key)->verify($expired_token, $ttl);
    ok(!$expired_verify, "bad expired verify (as expected)");

    my $expired_decrypttext = Fernet($expired_key)->decrypt($expired_token, $ttl);
    is($expired_decrypttext, undef, "bad expired decrypt (as expected)");

    $fernet = Fernet($b64_key);
    my $ttl_verify = Fernet($b64_key)->verify($token, $ttl);
    ok($ttl_verify, "good unexpired verify");

    my $ttl_decrypttext = Fernet($b64_key)->decrypt($token, $ttl);
    is($ttl_decrypttext, $plaintext, "good unexpired decrypt");

    is($fernet->to_string(), $b64_key, "good to_string serialisation");
    is("$fernet",            $b64_key, "good stringification");
}

done_testing();
