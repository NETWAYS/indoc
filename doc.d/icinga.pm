# File is Part of inDoc, (c) 2015 NETWAYS GmbH
# Licensed unter the Terms of GPL2+

package icinga;

# includes
use lib qw(lib ../lib .. doc.d);
use strict;
use File::Basename;
use inDoc::ConfigReader;

# package information
our $pkg;
$pkg->{name}        = 'icinga';
$pkg->{version}     = '0.1';
$pkg->{description} = 'icinga detection module';

# map variables from inDoc.pm --> easier handling and typing
my $msg = $inDoc::msg;
my $cfg = $inDoc::cfg;
my $dcy = $inDoc::discovery;
my $hlp = $inDoc::helper;
my $opt = $inDoc::opt;

# get and merge config
my $moduleConfig = inDoc::ConfigReader->new();
$moduleConfig->load($inDoc::basedir.'/'.dirname(__FILE__).'/'.$pkg->{name}.'.ini');
$cfg = { %$cfg, %$moduleConfig };

sub run {
	my (@result, $result);
	my ($icinga_config_path, $icinga_config, $icinga_version);

	# try to find a running icinga process
	$msg->verbose("Try to find a running icinga process");
	$result = $hlp->getProcessByName('icinga -d');
	
	# do we have a running process?
	if (my $icinga_process = (keys %{$result})[0]) {
		$dcy->store('icinga_process', $result);

		# find icinga.cfg
		my @val = split(/\s+/, $icinga_process);
		foreach(@val) { $icinga_config_path = $_ if $_ =~ /icinga.cfg/; }

		# we have a process? fine... save the icinga version!
		my $icinga_binary = (split(/\s+/, $icinga_process))[0];
		@result = $hlp->execCMD("$icinga_binary -V");
		foreach(@result) { $icinga_version = $_ if $_ =~ /^Icinga\s+[0-9\.]+/; }
		$dcy->store('icinga_version', $icinga_version);
	} else {
		# we do not have a running process
		# try to find it on the hard way...
		$msg->verbose("Can't find icinga.cfg by running process; try by search the filesystem");

		# create an array with all search paths (from config and cli options)
		my @search_paths = split(/\s*,\s*/, $cfg->{icinga}->{searchPaths});
		my @option_paths = split(/\s*,\s*/, $opt->{additional}) if defined $opt->{additional};
		foreach(@option_paths) { push(@search_paths, $_); }

		# search in each path
		foreach(@search_paths) {
			@result = $hlp->find('icinga.cfg', $_);
			$icinga_config_path = $result[0] if defined $result[0];
			last if defined $result[0];
		}
	}

	# save icinga.cfg
	if (defined $icinga_config_path) {
		$dcy->store('icinga_config_path', $icinga_config_path);
		@result = $hlp->execCMD("cat $icinga_config_path | grep -v \\# | sort | uniq");
		if ($result[0] == 0) {
			# remove non-icinga lines from result
			splice @result, 0, 2;
	
			# re-sort config lines
			foreach(@result) {
				my ($name, $value) = (split(/\s*=\s*/, $_))[0,1];
				$icinga_config->{$name} = $value;
			}
	
			$dcy->store('icinga_config', $icinga_config);
		} else {
			$msg->warning("Found $icinga_config_path, but was not able to get it");
		}
	} else {
		$msg->warning("There's no running icinga and i can't find icinga.cfg manually -> skip module $pkg->{name}");
	}
	
	# at the end, save log
	if (defined $icinga_config->{log_file}) {
		$hlp->saveFile($icinga_config->{log_file}) if -e $icinga_config->{log_file};
	}
	if (defined $icinga_config->{debug_file}) {
		$hlp->saveFile($icinga_config->{debug_file}) if -e $icinga_config->{debug_file};
	}
}

1;
