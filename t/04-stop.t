use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel::Stop;

package My::Stop {
    our @ISA = 'DBIx::Squirrel::Stop';
}

subtest 'Stop carries the arguments it was given' => sub {
    is dies { Stop() }, ['DBIx::Squirrel::Stop'], 'none';
    is dies { Stop(1, undef, 'x') }, ['DBIx::Squirrel::Stop', 1, undef, 'x'],
        'several, undef among them';
};

subtest 'throw is blessed into the class it was called on' => sub {
    my $stop = dies { DBIx::Squirrel::Stop->throw(1) };
    is ref($stop), 'DBIx::Squirrel::Stop',      'the class itself';
    is $stop,      ['DBIx::Squirrel::Stop', 1], 'carrying its arguments';

    my $sub = dies { My::Stop->throw(2) };
    is ref($sub), 'My::Stop', 'a subclass';
    isa_ok $sub, ['DBIx::Squirrel::Stop'], 'which is still a Stop';
    is $sub, ['My::Stop', 2], 'carrying its arguments';
};

subtest 'Stop is exported by default' => sub {

    package Importing {    ## no critic (Modules::ProhibitMultiplePackages)
        use DBIx::Squirrel::Stop;
    }
    ok Importing->can('Stop'), 'by default';

    package Not::Importing {    ## no critic (Modules::ProhibitMultiplePackages)
        use DBIx::Squirrel::Stop ();
    }
    ok !Not::Importing->can('Stop'), 'not when told not to';
};

subtest 'a Stop explains itself as a string' => sub {
    is '' . dies { Stop() }, "Stop used outside a pipeline\n";
    is '' . dies { My::Stop->throw }, "Stop used outside a pipeline\n",
        'a subclass too';
};

done_testing;
