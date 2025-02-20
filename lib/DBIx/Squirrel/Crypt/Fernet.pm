use strict;
use warnings;
use 5.010_001;

package    # hide from PAUSE
    DBIx::Squirrel::Crypt::Fernet;

=head1 NAME

DBIx::Squirrel::Crypt::Fernet

=head1 SYNOPSIS

    #############################
    # Object-oriented Interface #
    #############################

    # Import the helper
    use DBIx::Squirrel::Crypt::Fernet 'Fernet';

    # Generate random key
    $fernet = Fernet();

    # Use pre-defined Base64-encoded key
    $fernet = Fernet($key);

    # Import nothing
    use DBIx::Squirrel::Crypt::Fernet;

    # Generate random key
    $fernet = DBIx::Squirrel::Crypt::Fernet->new();

    # Use pre-defined Base64-encoded key
    $fernet = DBIx::Squirrel::Crypt::Fernet->new($key);

    # Encrypt message
    $token = $fernet->encrypt($message);

    # Decrypt token
    $message = $fernet->decrypt($token);

    # Verify token
    $bool = $fernet->verify($token);

    # Decrypt token, check time-to-live (secs) has not expired
    $message = $fernet->decrypt($token, $ttl);

    # Verify token, check time-to-live (secs) has not expired
    $bool = $fernet->verify($token, $ttl);

    # Retrieve Base64-encoded key
    $key = $fernet->tostring();
    $key = "$fernet";

    ######################
    # Exported functions #
    ######################

    # Import functions
    use DBIx::Squirrel::Crypt::Fernet qw(
        generatekey
        encrypt
        decrypt
        verify
    );

    # Import Crypt::Fernet-like interface
    use DBIx::Squirrel::Crypt::Fernet qw(
        fernet_genkey
        fernet_encrypt
        fernet_decrypt
        fernet_verify
    );

    # Generate a Base64-encoded random key
    $key = generatekey();
    $key = fernet_genkey();

    # Encrypt message
    $token = encrypt($key, $message);
    $token = fernet_encrypt($key, $message);

    # Decrypt token
    $message = decrypt($key, $token);
    $message = fernet_decrypt($key, $token);

    # Verify token
    $bool = verify($key, $token);
    $bool = fernet_verify($key, $token);

    # Decrypt token, check time-to-live (secs) has not expired
    $message = decrypt($key, $token, $ttl);
    $message = fernet_decrypt($key, $token, $ttl);

    # Verify token, check time-to-live (secs) has not expired
    $bool = verify($key, $token, $ttl);
    $bool = fernet_verify($key, $token, $ttl);

=head1 DESCRIPTION

Fernet takes a user-provided message (an arbitrary sequence of bytes), a
256-bit key, and the current time, and it produces a token containing the
message in a form that can't be read or altered without the key.

See L<https://github.com/fernet/spec/blob/master/Spec.md> for more detail.

=cut

our @ISA = qw(Exporter);
our @EXPORT;
our @EXPORT_OK = qw(
    fernet_decrypt  fernet_encrypt  fernet_genkey   fernet_verify
    decrypt         encrypt         generatekey     verify
    Fernet
);
our %EXPORT_TAGS = ('all' => \@EXPORT_OK);
our $VERSION     = '1.0.0';

use Crypt::CBC            ();
use Crypt::Rijndael       ();
use Digest::SHA           qw(hmac_sha256);
use Exporter              ();
use MIME::Base64::URLSafe qw(urlsafe_b64decode urlsafe_b64encode);
use namespace::clean;
use overload '""' => \&tostring;    # overload after namespace::clean for stringification to work

my $TOKEN_VERSION = pack("H*", '80');

{
    use bytes;

    sub _timebytes {
        return unpack('V', reverse(shift));
    }

    sub _timestamp {
        local $_;
        my $t = time();
        my @p = map(substr(pack('I', ($t >> $_ * 8) & 0xFF), 0, 1), 0 .. 7);
        return join('', reverse(@p));
    }
}

sub _randomkey {
    return Crypt::CBC->random_bytes(32);
}

sub _padb64 {
    my $b64 = urlsafe_b64encode(shift);
    return $b64 . '=' x (4 - length($b64) % 4);
}

=head2 EXPORTED FUNCTIONS

=head3 C<Fernet>

    $obj = Fernet();
    $obj = Fernet($key);

Returns a new C<DBIx::Squirrel::Crypt::Fernet> object. If no arguments are
passed then a random key will be generated. Alternatively, a Base64-encoded
key may be passed as the only argument.

The blessed scalar reference representing the object wraps the decoded bytes
of the key. Care should be taken not to display this binary value, but to use
the C<tostring> method (or stringification) to encode it as Base64.

=cut

sub Fernet {
    return __PACKAGE__->new(@_);
}

=head3 C<generatekey>

    $key = generatekey();

Returns a Base64-encoded randomly-generated key.

=head3 C<encrypt>

    $token = encrypt($key, $message);

Encrypts a message, returning a Base64-encode token.

=head3 C<decrypt>

    $message = decrypt($key, $token);
    $message = decrypt($key, $token, $ttl);

Decrypts the Base64-encoded token and returnsthe decrypted message. If
the token could not be decrypted or it has expired, then C<undef> will
be returned.

=head3 C<verify>

    $bool = verify($key, $token);
    $bool = verify($key, $token, $ttl);

Returns true if the token was encrypted using the same key and, if the
C<$ttl> (time-to-live) argument is supplied, has not expired.

=head3 The legacy C<Crypt::Fernet> interface

At the time I wanted to use Wan Leung Wong's C<Crypt::Fernet> package, it had
a few testing failures and would not build. I'm pretty sure the C<Crypt::CBC>
dependency introduced a breaking change. I did submit a fix, but deployment
and communication have been problematic. It has probably been fixed by now,
but I have decided to rework the original package, extend the interface,
and have kept this namespace active. Nevertheless, the lion's share of the
credit should go to the author of the original work.

The original C<Crypt::Fernet> package exported four functions as its primary
public interface, and this package also offers the same:

=over

=item * C<fernet_decrypt>

=item * C<fernet_genkey>

=item * C<fernet_encrypt>

=item * C<fernet_verify>

=back

=cut

=head3 C<fernet_genkey>

    $key = fernet_genkey();

Returns a Base64-encoded randomly-generated key.

=cut

sub fernet_genkey {
    goto &generatekey;
}

=head3 C<fernet_encrypt>

    $token = fernet_encrypt($key, $message);

Encrypts a message, returning a Base64-encode token.

=cut

sub fernet_encrypt {
    goto &encrypt;
}

=head3 C<fernet_decrypt>

    $message = fernet_decrypt($key, $token);
    $message = fernet_decrypt($key, $token, $ttl);

Decrypts the Base64-encoded token and returnsthe decrypted message. If
the token could not be decrypted or it has expired, then C<undef> will
be returned.

=cut

sub fernet_decrypt {
    goto &decrypt;
}

=head3 C<fernet_verify>

    $bool = fernet_verify($key, $token);
    $bool = fernet_verify($key, $token, $ttl);

Returns true if the token was encrypted using the same key and, if the
C<$ttl> (time-to-live) argument is supplied, has not expired.

=cut

sub fernet_verify {
    goto &verify;
}

=head2 METHODS

=head3 C<new>

    $obj = DBIx::Squirrel::Crypt::Fernet->new();
    $obj = DBIx::Squirrel::Crypt::Fernet->new($key);

Returns a new C<DBIx::Squirrel::Crypt::Fernet> object. If no arguments are
passed then a random key will be generated. Alternatively, a Base64-encoded
key may be passed as the only argument.

The blessed scalar reference representing the object wraps the decoded bytes
of the key. Care should be taken not to display this binary value, but to use
the C<tostring> method (or stringification) to encode it as Base64.

=cut

sub new {
    my($class, $b64key) = @_;
    my $key  = $b64key ? urlsafe_b64decode($b64key) : _randomkey();
    my $self = {
        key            => $key,
        signing_key    => substr($key, 0,  16),
        encryption_key => substr($key, 16, 16),
    };
    return bless $self, $class;
}

=head3 C<generatekey>

    $key = $obj->generatekey();
    $key = DBIx::Squirrel::Crypt::Fernet->generatekey();

Returns a Base64-encoded randomly-generated key.

=cut

sub generatekey {
    return _padb64(_randomkey());
}

=head3 C<encrypt>

    $token = $obj->encrypt($message);

Encrypts a message, returning a Base64-encode token.

=cut

sub encrypt {
    my($self_or_b64key, $data)           = @_;
    my($signing_key,    $encryption_key) = do {
        if (UNIVERSAL::isa($self_or_b64key, __PACKAGE__)) {
            @{$self_or_b64key}{qw(signing_key encryption_key)};
        }
        else {
            my $key = urlsafe_b64decode($self_or_b64key);
            substr($key, 0, 16), substr($key, 16, 16);
        }
    };
    my $iv         = Crypt::CBC->random_bytes(16);
    my $ciphertext = Crypt::CBC->new(
        -cipher      => 'Rijndael',
        -header      => 'none',
        -iv          => $iv,
        -key         => $encryption_key,
        -keysize     => 16,
        -literal_key => 1,
        -padding     => 'standard',
    )->encrypt($data);
    my $token = $TOKEN_VERSION . _timestamp() . $iv . $ciphertext;
    return _padb64($token . hmac_sha256($token, $signing_key));
}

=head3 C<decrypt>

    $message = $obj->decrypt($token);
    $message = $obj->decrypt($token, $ttl);

Decrypts the Base64-encoded token and returnsthe decrypted message. If
the token could not be decrypted or it has expired, then C<undef> will
be returned.

=cut

sub decrypt {
    my($self_or_b64key, $b64token, $ttl) = @_;
    return unless verify($self_or_b64key, $b64token, $ttl);
    my $encryption_key = do {
        if (UNIVERSAL::isa($self_or_b64key, __PACKAGE__)) {
            $self_or_b64key->{encryption_key};
        }
        else {
            substr(urlsafe_b64decode($self_or_b64key), 16, 16);
        }
    };
    my $token      = urlsafe_b64decode($b64token);
    my $ciphertext = substr($token, 25, length($token) - 32 - 25);
    return Crypt::CBC->new(
        -cipher      => 'Rijndael',
        -header      => 'none',
        -iv          => substr($token, 9, 16),
        -key         => $encryption_key,
        -keysize     => 16,
        -literal_key => 1,
        -padding     => 'standard',
    )->decrypt($ciphertext);
}

=head3 C<verify>

    $bool = $obj->verify($token);
    $bool = $obj->verify($token, $ttl);

Returns true if the token was encrypted using the same key and, if the
C<$ttl> (time-to-live) argument is supplied, has not expired.

=cut

sub verify {
    my($self_or_b64key, $b64token, $ttl) = @_;
    my $signing_key = do {
        if (UNIVERSAL::isa($self_or_b64key, __PACKAGE__)) {
            $self_or_b64key->{signing_key};
        }
        else {
            substr(urlsafe_b64decode($self_or_b64key), 0, 16);
        }
    };
    my $token = urlsafe_b64decode($b64token);
    return !!0
        if $TOKEN_VERSION ne substr($token, 0, 1)
        || $ttl && time - _timebytes(substr($token, 1, 8)) > $ttl;
    my $digest = substr($token, length($token) - 32, 32, '');    # 4-arg substr removes $digest from $token
    return $digest eq hmac_sha256($token, $signing_key);
}

=head3 C<tostring>

    $key = $obj->tostring();
    $key = "$obj";

Returns the Base64-encoded key.

=cut

sub tostring {
    return _padb64(shift->{key});
}

1;
