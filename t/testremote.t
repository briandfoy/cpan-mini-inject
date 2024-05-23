use Test::More;

use CPAN::Mini::Inject;
use lib 't/lib';
use localserver;

my $port =  empty_port();
my( $pid ) = start_server($port);
diag( "$$: PORT: $port" ) if $ENV{TEST_VERBOSE};
diag( "$$: PID: $pid" ) if $ENV{TEST_VERBOSE};

my $url = "http://localhost:$port/";

for( 1 .. 4 ) {
  my $sleep = $_ * 2;
  sleep $sleep;
  diag("Sleeping $sleep seconds waiting for server") if $ENV{TEST_VERBOSE};
  last if can_fetch($url);
}

my $mcpi = CPAN::Mini::Inject->new;
$mcpi->loadcfg( 't/.mcpani/config' )->parsecfg;
$mcpi->{config}{remote} =~ s/:\d{5}\b/:$port/;

$mcpi->testremote;
is( $mcpi->{site}, $url, "Site URL is $url" );

$mcpi->loadcfg( 't/.mcpani/config_badremote' )->parsecfg;
$mcpi->{config}{remote} =~ s/:\d{5}\b/:$port/;

SKIP: {
  skip 'Test fails with funky DNS providers', 1
   if can_fetch( 'http://blahblah' );
  # This fails with OpenDNS &c
  $mcpi->testremote;
  is( $mcpi->{site}, $url, 'Selects correct remote URL' );
}

kill( 9, $pid );
unlink( 't/testconfig' );

done_testing();
