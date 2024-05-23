use Test::More;

use LWP;
use CPAN::Mini::Inject;
use lib 't/lib';

BEGIN {
  plan skip_all => "HTTP::Server::Simple required to test update_mirror"
   if not eval "use CPANServer; 1";
  plan skip_all => "Net::EmptyPort required to test update_mirror"
   if not eval "use Net::EmptyPort; 1";
}

my $port =  empty_port();
my( $pid ) = start_server($port);
diag( "$$: PORT: $port" );
diag( "$$: PID: $pid" );

pass();

my $url = "http://localhost:$port/";
diag( "$$: URL $url" );

for( 1 .. 4 ) {
  my $sleep = $_ * 2;
  sleep $sleep;
  diag("Sleeping $sleep seconds waiting for server");
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


sub can_fetch { LWP::UserAgent->new->get( shift )->is_success }

sub start_server {
	my( $port ) = @_;

	my $child_pid = fork;

	return $child_pid unless $child_pid == 0;

	require HTTP::Daemon;
	require HTTP::Status;

	my $d = HTTP::Daemon->new( LocalPort => $port ) or return;
	while (my $c = $d->accept) {
		while (my $r = $c->get_request) {
			if ($r->method eq 'GET') {
				$c->send_file_response('t/html/index.html');
				}
			else {
				$c->send_error(HTTP::Status::RC_FORBIDDEN)
				}
			}
		$c->close;
		undef($c);
		}

	exit;
	}
