use Test::More;

use LWP;
use CPAN::Mini::Inject;
use lib 't/lib';

BEGIN {
  plan skip_all => "HTTP::Server::Simple required to test update_mirror"
   if not eval "use CPANServer; 1";
  plan skip_all => "Net::EmptyPort required to test update_mirror"
   if not eval "use Net::EmptyPort; 1";
  plan tests => 3;
}

my $port = Net::EmptyPort::empty_port;
my $url = "http://localhost:$port/";

my $server = CPANServer->new( $port );
my $pid    = $server->background;
ok( $pid, 'HTTP Server started' );
$SIG{__DIE__} = sub { kill( 9, $pid ) };

for( 1 .. 4 ) {
  my $sleep = $_ * 2;
  diag("Sleeping $sleep seconds waiting for server");
  last if can_fetch($url);
}

my $mcpi = CPAN::Mini::Inject->new;
$mcpi->loadcfg( 't/.mcpani/config' )->parsecfg;
$mcpi->{config}{remote} =~ s/:\d{5}\b/:$port/;
diag( "CONFIG: " . Dumper($mcpi->{config}); use Data::Dumper;

$mcpi->testremote;
is( $mcpi->{site}, $url, 'Correct remote URL' );

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

sub can_fetch { LWP::UserAgent->new->get( shift )->is_success }
