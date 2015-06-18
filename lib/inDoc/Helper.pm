# File is Part of inDoc, (c) 2015 NETWAYS GmbH
# Licensed unter the Terms of GPL2+

package inDoc::Helper;

=head1 NAME

inDoc::Helper - provides inDoc helper functions for easier programming

=cut

# includes
use strict;

BEGIN {
        unshift @INC, '.';
        unshift @INC, 'lib/';
}



=head2 function: new()

B<< my $helper = inDoc::Helper->new(); >>

Create a new helper handler object.

=cut 

sub new {
	my $class = shift;
	my $self = {};
	bless $self, $class;
}



=head2 function: execCMD(<command>)

B<< my @result = $helper->execCMD('date'); >>

Execute a command and return the result in an array.

=cut 

sub execCMD {
	my $class = shift;
	my $self  = shift;
	my $msg   = $inDoc::msg;
	my @output;

	# exec command
	$msg->verbose("Execute command '$self'");
	open my $HANDLE, "$self |";
	while (my $line = <$HANDLE>) {
		chomp($line);
		push(@output, $line);
	}
	close($HANDLE);

	# errors?
	my $returnCode = $?;

	# add return code and return data
	unshift(@output, $returnCode);
	return @output;
}



=head2 function: getProcessByName([<regex>])

B<< my $processes = $helper->getProcessByName(); >>

B<< my $processes = $helper->getProcessByName('^/usr/sbin/icinga -d'); >>

Returns a hasref of processes.

Return values can be filtered with regex (optional).

=cut

sub getProcessByName {
	my $class = shift;
	my $self  = shift;
	my $hlp   = $inDoc::helper;
	my $data;

	# get processes
	my @output = $hlp->execCMD('ps waxl');

	# remove first two lines (return code and header of ps command)
	splice @output, 0, 2;

	# re-sort elements
	foreach my $line (@output) {
		# get single rows
		my @val = split(/\s+/, $line);

		# save needed data
		my $UID = $val[1];
		my $PID = $val[2];
		my $VSZ = $val[6];
		my $RSS = $val[7];
		my $COMMAND = $val[12];
		
		# fullfill $COMMAND (if needed)
		if ($#val >= 13) {
			for (my $i = 13; $i <= $#val; $i++) { $COMMAND .= ' '.$val[$i]; }
		}

		# store (filtered) data
		if (!defined($self) || $COMMAND =~ /$self/) {
			$data->{$COMMAND}->{$PID}->{command}	= $COMMAND;
			$data->{$COMMAND}->{$PID}->{uid}	= $UID;
			$data->{$COMMAND}->{$PID}->{pid}	= $PID;
			$data->{$COMMAND}->{$PID}->{vsz}	= $VSZ;
			$data->{$COMMAND}->{$PID}->{rss}	= $RSS;
		}
	}

	return $data;
	
}



=head2 function: getFileStats(<path_to_file>)

B<< my $filestats = $helper->getFileStats('/etc/icinga/icinga.cfg'); >>

Returns file stats of a specified file as hashref.

Sample return values:

I<< $filestats->{path} = '/etc/icinga/icinga.cfg'; >>

I<< $filestats->{permissions} = '-rw-r--r--'; >>

I<< $filestats->{user} = 'icingauser'; >>

I<< $filestats->{group} = 'icingagroup'; >>

I<< $filestats->{size} = '48K'; >>

I<< $filestats->{modified} = 'Jan 4 16:18'; >>

=cut 

sub getFileStat {
	my $class = shift;
	my $file  = shift;
	my $hlp   = $inDoc::helper;
	my $data;

	# get file stats
	my @output = $hlp->execCMD("ls -lah $file");

	# re-format
	if ($output[0] == 0) {
		my ($permissions, $user, $group, $size, $month, $day, $time) = (split(/\s+/, $output[1]))[0,2,3,4,5,6,7];

		$data->{path}		= $file;
		$data->{permissions}	= $permissions;
		$data->{user}		= $user;
		$data->{group}		= $group;
		$data->{size}		= $size;
		$data->{modified}	= "$month $day $time";

		return $data;
	}
}



=head2 function: find(<filename>, <path>)

B<< my @foundFiles = $helper->find('icinga.cfg', '/etc'); >>

Returns an array with found files

=cut

sub find {
        my $class  = shift;
        my $target = shift;
	my $path   = shift;
        my $hlp    = $inDoc::helper;

        # get processes
        my @output = $hlp->execCMD("find $path -name '$target' 2>/dev/null");

        # remove first line (return code)
        splice @output, 0, 1;

	return @output;
}



=head2 function: saveFile(<path_to_file>)

B<< $helper->saveFile('/etc/icinga/icinga.cfg'); >>

Save specified file in inDoc output dir.

=cut

sub saveFile {
	my $class     = shift;
	my $file      = shift;
	my $cfg       = $inDoc::cfg;
	my $hlp       = $inDoc::helper;
	my $msg       = $inDoc::msg;
	my $outputDir = $cfg->{global}->{outputDir}.'/savedFiles';


	if (!-e $outputDir) {
		my $result = `mkdir $outputDir 2>&1`;
		(defined($result) && $result ne '')
			? $msg->error("Create output directory '$outputDir' failed: $result")
			: $msg->info("Create output directory '$outputDir'");
	}

	$msg->info("Save file '$file'");
	$hlp->execCMD("cp $file $outputDir");
}



=head2 function: getMemoryStatus([<process_name>])

B<< my $meminfo = $helper->getMemoryStatus(); >>

B<< my $meminfo = $helper->getMemoryStatus('^MemFree'); >>

Returns a hasref of /proc/meminfo.

Return values can be filtered with regex (optional).

=cut

sub getMemoryStatus {
        my $class = shift;
        my $self  = shift;
        my $hlp   = $inDoc::helper;
        my $data;

        # get processes
        my @output = $hlp->execCMD('cat /proc/meminfo');

        # remove first line (return code)
        splice @output, 0, 1;

        # re-sort elements 
        foreach my $line (@output) {
		my ($type, $value) = (split(/:\s+/, $line))[0,1];

		# store (filtered) data
		if (!defined($self) || $type =~ /$self/) {
			$data->{$type} = $value;
		}
	}

	return $data;
}



=head2 function: getOSType()

B<< my $os_info = $helper->getOSType(); >>

Returns a hashref with OS type and version.

Sample return values:

I<< $os_info->{ostype} = 'debian'; >>

I<< $os_info->{version} = '7.7'; >>

=cut

sub getOSType {
	my $class = shift;
	my $hlp   = $inDoc::helper;
	my $data;

	use Linux::Distribution qw(distribution_name distribution_version);
	my $detection = Linux::Distribution->new;

	if ($detection->distribution_name()) {
	        $data->{version} = $detection->distribution_version();
		$data->{ostype}  = $detection->distribution_name()
	} else {
		$data->{version} = 'unknown';
		$data->{ostype} = 'unknown';
	}

	return $data;
}

1;
