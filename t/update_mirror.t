use strict;
use warnings;

use Test::More;

use CPAN::Mini::Inject;
use File::Path;
use File::Spec::Functions;

use lib 't/lib';
use localserver;

subtest 'remove mirror dir' => sub {
	rmtree( [ catdir( 't', 'mirror' ) ], 0, 1 );
	ok ! -e catdir( 't', 'mirror' );
	};

my $url;
my $port;
my $pid;
subtest 'start local server' => sub {
	$port =  empty_port();
	( $pid ) = start_server($port);

	diag( "$$: PORT: $port" ) if $ENV{TEST_VERBOSE};
	diag( "$$: PID: $pid" ) if $ENV{TEST_VERBOSE};

	$url = "http://localhost:$port/";

	for( 1 .. 4 ) {
	  my $sleep = $_ * 2;
	  sleep $sleep;
	  diag("Sleeping $sleep seconds waiting for server") if $ENV{TEST_VERBOSE};
	  last if can_fetch($url);
	  }

	ok can_fetch($url), "URL $url is available";
	};

my $mcpi;
subtest 'setup' => sub {
	my $class = 'CPAN::Mini::Inject';
	use_ok $class;
	$mcpi = $class->new;
	isa_ok $mcpi, $class;
	};

subtest 'testremote' => sub {
	$mcpi->loadcfg( catfile qw( t .mcpani config) )->parsecfg;
	$mcpi->{config}{remote} =~ s/:\d{5}\b/:$port/;

	ok can_fetch($url), "URL $url is available";

	eval { $mcpi->testremote } or print STDERR "1 testremote died: $@";
	eval { $mcpi->testremote } or print STDERR "2 testremote died: $@";

	ok can_fetch($url), "URL $url is still available";

	is( $mcpi->{site}, $url, "Site URL is $url" );
	};

subtest 'update mirror' => sub {
	mkdir( catdir( 't', 'mirror' ) );
	ok( -e catfile( qw(t mirror) ), 't/mirror exists' );

	ok can_fetch($url), "URL $url is available";

	eval {
		$mcpi->update_mirror(
		  remote => $url,
		  local  => catdir( 't', 'mirror' ),
		  trace  => 1,
		  );
		} or print STDERR "update_mirror died: $@";
	};

subtest 'mirror state' => sub {
	ok( -e catfile( qw(t mirror authors 01mailrc.txt.gz) ), '01mailrc.txt.gz exists' );
	ok( -e catfile( qw(t mirror modules 02packages.details.txt.gz) ), '02packages.details.txt.gz exists' );
	ok( -e catfile( qw(t mirror modules 03modlist.data.gz) ), '03modlist.data.gz exists' );
	ok( -e catfile( qw(t mirror authors id R RJ RJBS CHECKSUMS) ), 'RJBS/CHECKSUMS exists' );
	ok( -e catfile( qw(t mirror authors id R RJ RJBS CPAN-Mini-2.1828.tar.gz) ), 'CPAN-Mini-2.1828.tar.gz exists' );
	ok( -e catfile( qw(t mirror authors id S SS SSORICHE CHECKSUMS) ), 'SSORICHE/CHECKSUMS exists' );
	ok( -e catfile( qw(t mirror authors id S SS SSORICHE CPAN-Mini-Inject-1.01.tar.gz) ), 'CPAN::Mini::Inject exixts' );
	};

sleep 1; # allow locks to expire
kill( 9, $pid );

subtest 'cleanup' => sub {
	rmtree( [ catdir( 't', 'mirror' ) ], 0, 1 );
	ok ! -e catdir( 't', 'mirror' );
	};

done_testing();






