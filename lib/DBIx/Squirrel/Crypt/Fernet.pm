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
our $VERSION              = '0.04';
our $FERNET_TOKEN_VERSION = pack("H*", '80');

sub fernet_decrypt { decrypt(@_) }

sub fernet_encrypt { encrypt(@_) }

sub fernet_genkey { generate_key() }

sub fernet_verify { verify(@_) }

sub Fernet {
    my $key = \(my $self = defined($_[0]) ? urlsafe_b64decode(shift) : undef);
    bless $key, 'Crypt::Fernet';
}

sub _padded_b64encode {
    my $b64 = urlsafe_b64encode(shift);
    return $b64 . ('=' x (4 - length($b64) % 4));
}

sub decrypt {
    my($key, $token, $ttl) = (
        UNIVERSAL::isa($_[0], __PACKAGE__) ? ${+shift} : urlsafe_b64decode(shift),
        urlsafe_b64decode(shift), @_,
    );
    return unless verify(_padded_b64encode($key), _padded_b64encode($token), $ttl);
    my $c_size     = length($token) - 25 - 32;
    my $ciphertext = substr($token, 25, $c_size);
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

sub _timestamp {
    local $_;
    use bytes;
    my $time       = time();
    my $time_64bit = '';
    $time_64bit .= substr(pack('I', ($time >> $_ * 8) & 0xFF), 0, 1) for 0 .. 7;
    return reverse($time_64bit);
}

sub encrypt {
    my($key, $data) = (
        UNIVERSAL::isa($_[0], __PACKAGE__) ? ${+shift} : urlsafe_b64decode(shift), @_,
    );
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
    my $t_prefix = $FERNET_TOKEN_VERSION . _timestamp() . $iv . $ciphertext;
    return _padded_b64encode($t_prefix . hmac_sha256($t_prefix, substr($key, 0, 16)));
}

sub generate_key { _padded_b64encode(Crypt::CBC->random_bytes(32)) }

sub key {
    if (UNIVERSAL::isa($_[0], __PACKAGE__)) {
        my $self = shift;
        ${$self} = defined($_[0]) ? urlsafe_b64decode(shift) : undef if @_;
        return ${$self};
    }
    else {
        return generate_key();
    }
}

sub verify {
    my($key, $token, $ttl) = (
        UNIVERSAL::isa($_[0], __PACKAGE__) ? ${+shift} : urlsafe_b64decode(shift),
        urlsafe_b64decode(shift), @_,
    );
    return !!0 if substr($token, 0, 1) ne $FERNET_TOKEN_VERSION;
    return !!0 if $ttl && $ttl < do {
        use bytes;
        time() - unpack('V', reverse(substr($token, 1, 8)));
    };
    my $len = length($token);
    my $signature = substr($token, $len - 32, $len, "");
    # ^ substr replaces signature portion with "", shortening the token by 32 chars
    return !!0 unless $signature eq hmac_sha256($token, substr($key, 0, 16));
    return !!1;
}

1;
