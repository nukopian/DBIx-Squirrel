requires 'perl', '5.036';
requires 'Carp';
requires 'DBI';
requires 'Data::Dumper';
requires 'Digest::SHA';
requires 'Exporter';
requires 'List::Util';
requires 'Ref::Util';
requires 'Sub::Util';
requires 'experimental';
requires 'namespace::clean';

on test => sub {
    requires 'DBD::SQLite';
    requires 'Test2::V0';
    requires 'Test2::Plugin::NoWarnings';
};

on develop => sub {
    requires 'CPAN::Uploader';
    requires 'Data::Dump';
    requires 'Perl::Critic';
    requires 'Perl::Tidy';
    requires 'Test2::Harness';
    requires 'UUID';
};
