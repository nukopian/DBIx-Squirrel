
=pod

=encoding UTF-8

=head1 NAME

DBIx::Squirrel::Crypt::Fernet

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

package    # hide from PAUSE
    DBIx::Squirrel::Crypt::Fernet;

use 5.010_001;
use strict;
use warnings;
use Exporter;
use namespace::clean;
use overload '""' => \&to_string;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw/
    fernet_decrypt
    fernet_encrypt
    fernet_genkey
    fernet_verify
    Fernet
    decrypt
    encrypt
    generate_key
    verify
    /;
our %EXPORT_TAGS = ('all' => \@EXPORT_OK);
our @EXPORT      = qw/Fernet/;
our $VERSION     = '1.0.0';

our $TOKEN_VERSION = pack("H*", '80');

use Crypt::Rijndael       ();
use Crypt::CBC            ();
use Digest::SHA           qw/hmac_sha256/;
use MIME::Base64::URLSafe qw/urlsafe_b64decode urlsafe_b64encode/;

sub fernet_decrypt { goto &decrypt }

sub fernet_encrypt { goto &encrypt }

sub fernet_genkey { goto &generate_key }

sub fernet_verify { goto &verify }

sub Fernet { __PACKAGE__->new(@_) }

sub decrypt {
    my($b64_key, $b64_token, $ttl) = @_;
    return unless verify($b64_key, $b64_token, $ttl);
    my $key = do {
        if (UNIVERSAL::isa($b64_key, __PACKAGE__)) {    # If used as method call, then blessed
            ${$b64_key};                                # scalar references the decoded key.
        }
        else {
            urlsafe_b64decode($b64_key);
        }
    };
    my $token         = urlsafe_b64decode($b64_token);
    my $ciphertextlen = length($token) - 25 - 32;
    my $ciphertext    = substr($token, 25, $ciphertextlen);
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
    my($b64_key, $data) = @_;
    my $key = do {
        if (UNIVERSAL::isa($b64_key, __PACKAGE__)) {    # If used as method call, then blessed
            ${$b64_key};                                # scalar references the decoded key.
        }
        else {
            urlsafe_b64decode($b64_key);
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
    my $pre_token = $TOKEN_VERSION . _timestamp() . $iv . $ciphertext;
    my $digest    = hmac_sha256($pre_token, substr($key, 0, 16));
    return _b64pad(urlsafe_b64encode($pre_token . $digest));
}

sub _timestamp {
    use bytes;
    local $_;
    my $time = time();
    my @t    = map { substr(pack('I', ($time >> $_ * 8) & 0xFF), 0, 1) } 0 .. 7;
    return join('', reverse(@t));
}

sub generate_key {
    return _b64pad(urlsafe_b64encode(Crypt::CBC->random_bytes(32)));
}

sub _b64pad {
    my($base64) = @_;
    return $base64 . '=' x (4 - length($base64) % 4);
}

sub to_string {
    my($self) = @_;
    return _b64pad(urlsafe_b64encode(${$self}));
}

sub verify {
    my($b64_key, $b64_token, $ttl) = @_;
    my $key = do {
        if (UNIVERSAL::isa($b64_key, __PACKAGE__)) {    # If used as method call, then blessed
            ${$b64_key};                                # scalar references the decoded key.
        }
        else {
            urlsafe_b64decode($b64_key);
        }
    };
    my $message       = urlsafe_b64decode($b64_token);
    my $token_version = substr($message, 0, 1);
    return !!0 if $token_version ne $TOKEN_VERSION;
    return !!0 if $ttl && time - _timebytes(substr($message, 1, 8)) > $ttl;
    my $token_sign    = substr($message, length($message) - 32, 32);
    my $signing_key   = substr($key,     0,                     16);
    my $pre_token     = substr($message, 0, length($message) - 32);
    my $verify_digest = hmac_sha256($pre_token, $signing_key);
    return $token_sign eq $verify_digest;
}

sub _timebytes {
    use bytes;
    return unpack('V', reverse(shift));
}

sub new {
    my($class, $b64_key) = @_;
    my $key = do {
        if (defined $b64_key) {
            urlsafe_b64decode($b64_key);
        }
        else {
            Crypt::CBC->random_bytes(32);
        }
    };
    return bless(\$key, __PACKAGE__);
}

1;

__END__

=head2 EXPORTED FUNCTIONS

=head3 Legacy C<Crypt::Fernet> functions

At the time I wanted to use Wan Leung Wong's C<Crypt::Fernet> package, it had
a few testing failures and would not build. Not his fault, as I'm pretty sure
the C<Crypt::CBC> dependency introduced a breaking change. I did submit a fix,
but deployment and communication have been problematic. It has probably been
fixed by now, but I have decided to rework the original package and extend
the interface, so have kept this package. Nevertheless, the lion's share of
the credit should go to the author of the original work.

The original C<Crypt::Fernet> package exports four functions as its primary
public interface:

=over

=item 1. C<fernet_decrypt>

=item 2. C<fernet_genkey>

=item 3. C<fernet_encrypt>

=item 4. C<fernet_verify>

=back

Those same four functions are also implemented and exported by the
C<DBIx::Squirrel::Crypt::Fernet> package.

=cut

=head3 C<fernet_decrypt>

    $data = fernet_decrypt($base64_key, $base64_token[, $ttl])

Executes a tail-call to C<decrypt> (see L<C<decrypt>> function).

=head3 C<fernet_encrypt>

    $base64_token = fernet_encrypt($base64_key, $data)

Executes a tail-call to C<encrypt> (see L<C<encrypt>> function).

=head3 C<fernet_genkey>

    $base64_key = fernet_genkey()

Executes a tail-call to C<generate_key> (see L<C<generate_key>> function).

=head3 C<fernet_verify>

    $bool = fernet_verify($base64_key, $base64_token[, $ttl])

Executes a tail-call to C<verify> (see L<C<verify>> function).

=head3 Other functions

=head3 C<decrypt>

    $data = decrypt($base64_key, $base64_token[, $ttl])

=head3 C<encrypt>

    $base64_token = encrypt($base64_key, $data)

=head3 C<generate_key>

    $base64_key = generate_key()

=head3 C<verify>

    $bool = verify($base64_key, $base64_token[, $ttl])

=head3 C<Fernet>

    $obj = Fernet([$base64_key])

Returns a new C<DBIx::Squirrel::Crypt::Fernet> object.

An optional Base64-encoded key may be passed to the function

=head2 METHODS

=head3 C<decrypt>

    $data = $obj->decrypt($base64_token[, $ttl])

=head3 C<encrypt>

    $base64_token = $obj->encrypt($data)

=head3 C<generate_key>

    $base64_key = DBIx::Squirrel::Crypt::Fernet->generate_key()
    $base64_key = $obj->generate_key()

=head3 C<verify>

    $bool = $obj->verify($base64_token[, $ttl])

=head3 C<new>

    $obj = DBIx::Squirrel::Crypt::Fernet->new([$base64_key])

=cut
