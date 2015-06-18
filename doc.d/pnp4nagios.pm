# File is Part of inDoc, (c) 2015 NETWAYS GmbH
# Licensed unter the Terms of GPL2+

package pnp4nagios;

# includes
use lib qw(lib ../lib .. doc.d);
use strict;
use File::Basename;
use inDoc::ConfigReader;

# package information
our $pkg;
$pkg->{name}        = 'pnp4nagios';
$pkg->{version}     = '0.1';
$pkg->{description} = 'pnp4nagios detection module';

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
	my ($pnp_config_path, $pnp_config);

	# try to find a running npcd process
	$msg->verbose("Try to find a running npcd process");
	$result = $hlp->getProcessByName('npcd -d');
	
	# do we have a running process?
	if (my $pnp_process = (keys %{$result})[0]) {
		$dcy->store('pnp_process', $result);

		# find npcd.cfg
		my @val = split(/\s+/, $pnp_process);
		foreach(@val) { $pnp_config_path = $_ if $_ =~ /npcd.cfg/; }
	} else {
		# we do not have a running process
		# try to find it on the hard way...
		$msg->verbose("Can't find npcd.cfg by running process; try by search the filesystem");

		# create an array with all search paths (from config and cli options)
		my @search_paths = split(/\s*,\s*/, $cfg->{pnp4nagios}->{searchPaths});
		my @option_paths = split(/\s*,\s*/, $opt->{additional}) if defined $opt->{additional};
		foreach(@option_paths) { push(@search_paths, $_); }

		# search in each path
		foreach(@search_paths) {
			@result = $hlp->find('npcd.cfg', $_);
			$pnp_config_path = $result[0] if defined $result[0];
			last if defined $result[0];
		}
	}

	# save pnp4nagios data
	if (defined $pnp_config_path) {
		$dcy->store('pnp_config_path', $pnp_config_path);
		@result = $hlp->execCMD("cat $pnp_config_path | grep -v \\# | sort | uniq");
		if ($result[0] == 0) {
			# remove non-icinga lines from result
			splice @result, 0, 2;
	
			# re-sort config lines
			foreach(@result) {
				my ($name, $value) = (split(/\s*=\s*/, $_))[0,1];
				$pnp_config->{$name} = $value;
			}
	
			$dcy->store('pnp_config', $pnp_config);
		} else {
			$msg->warning("Found $pnp_config_path, but was not able to get it");
		}
	} else {
		$msg->warning("There's no running npcd and i can't find npcd.cfg manually -> skip module $pkg->{name}");
	}
	
	# at the end, save log
	if (defined $pnp_config->{log_file}) {
	        $hlp->saveFile($pnp_config->{log_file}) if -e $pnp_config->{log_file};
	}
}

1;
