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
use Crypt::Rijndael ();
use Crypt::CBC      ();
use Digest::SHA     qw/hmac_sha256/;
use Exporter;
use MIME::Base64::URLSafe;
use namespace::clean;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw/
    Fernet
    fernet_decrypt
    fernet_encrypt
    fernet_genkey
    fernet_verify
    /;
our %EXPORT_TAGS = ('all' => \@EXPORT_OK);
our @EXPORT;
our $VERSION = '0.04';

# Ours is a drop-in replacement for the currently non-functional
# Crypt::Fernet, so we'll alias the namespace in the hope that my
# PR with fixes is merged by Crypt::Fernet's author.

*Crypt::Fernet:: = *DBIx::Squirrel::Crypt::Fernet::;

our $FERNET_TOKEN_VERSION = pack("H*", '80');

sub _bytes_to_time {
    my($bytes) = @_;
    use bytes;
    return unpack('V', reverse($bytes));
}

sub _b64encode {
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

sub fernet_decrypt {
    return decrypt(@_);
}

sub fernet_encrypt {
    return encrypt(@_);
}

sub fernet_genkey {
    return generate_key();
}

sub fernet_verify {
    return verify(@_);
}

sub Fernet {
    return bless(
        do {
            \(my $self = defined($_[0]) ? urlsafe_b64decode(shift) : undef);
        },
        'Crypt::Fernet',
    );
}

sub decrypt {
    my($key, $token, $ttl) = do {
        if (UNIVERSAL::isa($_[0], __PACKAGE__)) {
            ${+shift}, urlsafe_b64decode(shift), @_;
        }
        else {
            urlsafe_b64decode(shift), urlsafe_b64decode(shift), @_;
        }
    };
    return unless verify(_b64encode($key), _b64encode($token), $ttl);
    my $size_c     = length($token) - 25 - 32;
    my $ciphertext = substr($token, 25, $size_c);
    return Crypt::CBC->new(
        -cipher      => 'Rijndael',
        -header      => 'none',
        -iv          => substr($token, 9,  16),
        -key         => substr($key,   16, 16),
        -keysize     => 16,
        -literal_key => 1,
        -padding     => 'standard',
    )->decrypt($ciphertext);
}

sub encrypt {
    my($key, $data) = do {
        if (UNIVERSAL::isa($_[0], __PACKAGE__)) {
            ${+shift}, @_;
        }
        else {
            urlsafe_b64decode(shift), @_;
        }
    };
    my $iv         = Crypt::CBC->random_bytes(16);
    my $ciphertext = Crypt::CBC->new(
        -cipher      => 'Rijndael',
        -header      => 'none',
        -iv          => $iv,
        -key         => substr($key, 16, 16),
        -keysize     => 16,
        -literal_key => 1,
        -padding     => 'standard',
    )->encrypt($data);
    my $pre_t = $FERNET_TOKEN_VERSION . _timestamp() . $iv . $ciphertext;
    return _b64encode($pre_t . hmac_sha256($pre_t, substr($key, 0, 16)));
}

sub generate_key {
    return _b64encode(Crypt::CBC->random_bytes(32));
}

sub key {
    return generate_key() unless UNIVERSAL::isa($_[0], __PACKAGE__);
    my $self = shift;
    if (@_) {
        ${$self} = defined($_[0]) ? urlsafe_b64decode(shift) : undef;
    }
    return ${$self};
}

sub verify {
    my($key, $token, $ttl) = do {
        if (UNIVERSAL::isa($_[0], __PACKAGE__)) {
            ${+shift}, urlsafe_b64decode(shift), @_;
        }
        else {
            urlsafe_b64decode(shift), urlsafe_b64decode(shift), @_;
        }
    };
    return !!0
        unless $FERNET_TOKEN_VERSION eq substr($token, 0, 1);
    return !!0
        if $ttl && time() - _bytes_to_time(substr($token, 1, 8)) > $ttl;
    my $size_t    = length($token) - 32;
    my $pre_t     = substr($token, 0, $size_t);
    my $signature = substr($token, $size_t);
    return !!0
        unless $signature eq hmac_sha256($pre_t, substr($key, 0, 16));
    return !!1;
}

1;
