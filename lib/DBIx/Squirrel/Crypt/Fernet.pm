# This is a reworking of Wan Leung Wong's Crypt::Fernet package. I wanted
# to use it, but it has testing errors, fixable errors in the code, and
# won't build, but credit for the work goes to him. I have a GitHub PR in
# with the author to fix the minor issues, but the code hasn't been touched
# in ten years, and there is radio-silence on my PR. So, because I need it,
# I'm pulling it into this distribution where I can maintain it, and where
# it has some chance of building. If I can get my fixes into the original
# and a dialogue with the original author then I'll probably use the
# patched Crypt::Fernet package. I'll make *additive* improvements to the
# original code so that they can be included in any future patches.
#
package    # hide from PAUSE
    DBIx::Squirrel::Crypt::Fernet;

use 5.010_001;
use strict;
use warnings;
use Exporter;
use namespace::clean;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw/
    fernet_decrypt
    fernet_encrypt
    fernet_genkey
    fernet_verify
    /;
our %EXPORT_TAGS = ('all' => \@EXPORT_OK);
our @EXPORT;
our $VERSION = '0.04';

our $FERNET_TOKEN_VERSION = pack("H*", '80');

# Preloaded methods go here.

sub fernet_decrypt { decrypt(@_) }
sub fernet_encrypt { encrypt(@_) }
sub fernet_genkey  { generate_key() }
sub fernet_verify  { verify(@_) }

use Crypt::Rijndael ();
use Crypt::CBC      ();
use Digest::SHA     qw/hmac_sha256/;
use MIME::Base64::URLSafe;

sub _bytes_to_time {
    my($bytes) = @_;
    use bytes;
    return unpack('V', reverse($bytes));
}

sub _base64_padded {
    my $base64 = urlsafe_b64encode(shift);
    return $base64 . ('=' x (4 - length($base64) % 4));
}

sub _timestamp {
    my $result = do {
        use bytes;
        my $time       = time();
        my $time_64bit = '';
        for my $index (0 .. 7) {
            $time_64bit .= substr(pack('I', ($time >> $index * 8) & 0xFF), 0, 1);
        }
        reverse($time_64bit);
    };
    return $result;
}

sub decrypt {
    my($key, $token, $ttl) = @_;
    return unless verify($key, $token, $ttl);
    my $k          = urlsafe_b64decode($key);
    my $t          = urlsafe_b64decode($token);
    my $size_c     = length($t) - 25 - 32;
    my $ciphertext = substr($t, 25, $size_c);
    return Crypt::CBC->new(
        -cipher      => 'Rijndael',
        -header      => 'none',
        -iv          => substr($t, 9,  16),
        -key         => substr($k, 16, 16),
        -keysize     => 16,
        -literal_key => 1,
        -padding     => 'standard',
    )->decrypt($ciphertext);
}

sub encrypt {
    my($key, $data) = @_;
    my $k          = urlsafe_b64decode($key);
    my $iv         = Crypt::CBC->random_bytes(16);
    my $ciphertext = Crypt::CBC->new(
        -cipher      => 'Rijndael',
        -header      => 'none',
        -iv          => $iv,
        -key         => substr($k, 16, 16),
        -keysize     => 16,
        -literal_key => 1,
        -padding     => 'standard',
    )->encrypt($data);
    my $t_pref = $FERNET_TOKEN_VERSION . _timestamp() . $iv . $ciphertext;
    return _base64_padded($t_pref . hmac_sha256($t_pref, substr($k, 0, 16)));
}

sub generate_key {
    return _base64_padded(Crypt::CBC->random_bytes(32));
}

sub verify {
    my($key, $token, $ttl) = @_;
    my $k = urlsafe_b64decode($key);
    my $t = urlsafe_b64decode($token);
    return !!0
        unless $FERNET_TOKEN_VERSION eq substr($t, 0, 1);
    return !!0
        if $ttl && time() - _bytes_to_time(substr($t, 1, 8)) > $ttl;
    my $size_t    = length($t) - 32;
    my $signature = substr($t, $size_t);
    my $t_pref    = substr($t, 0, $size_t);
    return !!0
        unless $signature eq hmac_sha256($t_pref, substr($k, 0, 16));
    return !!1;
}

1;
