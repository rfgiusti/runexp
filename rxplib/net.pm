package rxplib::net;

use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(recvlong);

# Receive a long message through a socket
# FIXME: thread will be permanently blocked if the full message is not sent
sub recvlong {
	my $socket = shift;
	my $length = shift;

	my $msg = "";
	while ($length) {
		my $buffer;
		$socket->recv($buffer, $length);
		$msg .= $buffer;
		$length -= length $buffer;
	}

	return $msg;
}

return 1;
