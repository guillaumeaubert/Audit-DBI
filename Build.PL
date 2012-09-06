use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'Audit::DBI',
	license             => 'artistic',
	dist_author         => q{Guillaume Aubert <aubertg@cpan.org>},
	dist_version_from   => 'lib/Audit/DBI.pm',
	build_requires      =>
	{
		'Config::Tiny'         => 0,
		'DBD::SQLite'          => 0,
		'DBI'                  => 0,
		'File::Spec'           => 0,
		'Test::Exception'      => 0,
		'Test::More'           => 0.94,
	},
	requires            =>
	{
		'perl'                 => 5.006,
		'Carp'                 => 0,
		'Data::Dumper'         => 0,
		'Data::Validate::Type' => 0,
		'HTML::Entities'       => 0,
		'MIME::Base64'         => 0,
		'Socket'               => 0,
		'Storable'             => 0,
		'Template::Plugin'     => 0,
		'Template::Stash'      => 0,
		'Try::Tiny'            => 0,
	},
	add_to_cleanup      =>
	[
		'Audit-DBI-*',
	],
	create_makefile_pl  => 'traditional',
	configure_requires  =>
	{
		'Module::Build'        => 0,
	},
	meta_merge          =>
	{
		resources              =>
		{
			repository  => 'https://sourceforge.net/p/perl-audit-dbi/code',
			homepage    => 'https://metacpan.org/release/Audit-DBI',
			bugtracker  => 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=audit-dbi',
		},
	},
);

$builder->create_build_script();
