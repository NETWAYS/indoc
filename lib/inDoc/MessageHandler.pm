# File is Part of inDoc, (c) 2015 NETWAYS GmbH
# Licensed unter the Terms of GPL2+

package inDoc::MessageHandler;

=head1 NAME

inDoc::MessageHandler - provide message handling functions

=cut

# includes
use strict;
use POSIX qw(strftime);
use Time::HiRes qw(time);
use Term::ANSIColor qw(:constants);

BEGIN {
	unshift @INC, '.';
	unshift @INC, 'lib/';
}



=head2 function: new()

B<< my $messages = inDoc::MessageHandler->new(); >>

Create a new message handler object.

=cut 

sub new {
	my $class = shift;
	my $self = {
		info => {},
		verbose => {},
		warning => {},
		error => {},
	};
	bless $self, $class;
}



# internal function; just stores the data
sub handleMessage {
	my $class = shift;
	my $self  = shift;
	my $type  = shift;

	$class->{$type}->{time()} = $self;
}



=head2 function: info(<message>)

B<< $messages->info('This is just an info...'"); >>

Print a info message to STDOUT and save it for later use.

=cut

sub info {
	my $class = shift; my $self = shift;
	handleMessage($class, $self, 'info');

	print strftime("%Y-%m-%d %H:%M:%S", localtime())." | INFO: ".$self."\n";
}



=head2 function: verbose(<message>)

B<< $messages->verbose('SuperDuper verbose output.'); >>

Print a verbose output to STDOUT and save it for later use.

Verbose output will only be shown with inDoc option -v.

=cut

sub verbose {
	my $class = shift; my $self = shift;
	handleMessage($class, $self, 'verbose');

	print strftime("%Y-%m-%d %H:%M:%S", localtime())." | VERBOSE: ".$self."\n" if defined $inDoc::opt->{verbose};
}



=head2 function: warning(<message>)

B<< $messages->warning('This is w_a_r_n_i_n_g'); >>

Print a warning message to STDOUT and save it for later use.

=cut
sub warning {
	my $class = shift; my $self = shift;
	handleMessage($class, $self, 'warning');

	print YELLOW, strftime("%Y-%m-%d %H:%M:%S", localtime())." | WARNING: ".$self."\n", RESET;
}



=head2 function: error(<message>)

B<< $messages->error('This is a big fat ERROR !!'); >>

Print an error message to STDOUT and save it for later use.

=cut

sub error {
	my $class = shift; my $self = shift;
	handleMessage($class, $self, 'error');

	print RED, strftime("%Y-%m-%d %H:%M:%S", localtime())." | ERROR: ".$self."\n", RESET;
	exit 1;
}

1;
