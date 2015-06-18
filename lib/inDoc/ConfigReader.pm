# File is Part of inDoc, (c) 2015 NETWAYS GmbH
# Licensed unter the Terms of GPL2+

package inDoc::ConfigReader;

=head1 NAME

inDoc::ConfigReader - functions for handling indoc config files

=cut

# includes
use strict;

BEGIN {
	unshift @INC, '.';
	unshift @INC, 'lib/';
}



=head2 function: new()

B<< my $config = inDoc::ConfigReader->new(); >>

Create a new config handler object.

=cut 

sub new {
	my $class = shift;
	my $self = {};

	bless $self, $class;
	return $self;
}



=head2 function: load(<cfgfile>)

B<< $config->load('/etc/foo/bar.ini'); >>

load an indoc config file; config will be converted to a hashref.

Example: If your config look like this...

I<< [MySuperDuperConfig] >>

I<< ; this is just a sample config variable >>

I<< foo = 'bar' >>

...you will get an hashref with $config->{MySuperDuperConfig}->{foo} = 'bar';

=cut

sub load {
	my $class   = shift;
	my $cfgfile = shift;
	my $msg     = $inDoc::msg;
	my $section;

	# load config file
	$msg->verbose("Load config file '$cfgfile'");
	open FILE, "<$cfgfile" or die "Can't open file '$cfgfile': $!";
	while (<FILE>) {
		# don't process empty or hashed lines
		if (defined $_ && $_ ne "\n" && $_ !~ /^\#/ && $_ !~ /^\;/) {
			# remove line break
			chomp($_);

			# do we have a new section?
			if ($_ =~ m/^\[[-_\d\w\s]*\]/) {
				# set section and remove square brackets
				$section = $_;
				$section =~ s/\[//g;
				$section =~ s/\]//g;
			} else {
				# store config items
				my @val = split(/\s*=\s*/, $_, 2);
				$class->{$section}->{$val[0]} = $val[1];
			}
		}
	}
	close FILE;
}



=head2 function: dump()

B<< $config->dump(); >>

Print loaded config to STDOUT.

=cut

sub dump {
	my $class = shift;

	foreach my $val1 (keys %{$class}) {
		print "[$val1]\n";

		foreach my $val2 (keys %{$class->{$val1}}) {
			print "\t$val2 = $class->{$val1}->{$val2}\n";
		}
	}
}

1;
