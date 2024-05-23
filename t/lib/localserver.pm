use File::Spec::Functions qw(catfile);
use Net::EmptyPort;

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
				my $file = (split m|/|, $r->uri->path)[-1];
				my $path = catfile 't', 'html', $file;
				if( -e $path ) {
					$c->send_file_response( catfile 't', 'html', $file);
					}
				else {
					$c->send_error(HTTP::Status::RC_NOT_FOUND)
					}
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

sub can_fetch { require LWP::UserAgent; LWP::UserAgent->new->get( shift )->is_success }

1;
