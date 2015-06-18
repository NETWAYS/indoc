# File is Part of inDoc, (c) 2015 NETWAYS GmbH
# Licensed unter the Terms of GPL2+

package ido;

# includes
use lib qw(lib ../lib .. doc.d);
use strict;
use File::Basename;
use inDoc::ConfigReader;

# package information
our $pkg;
$pkg->{name}        = 'ido';
$pkg->{version}     = '0.1';
$pkg->{description} = 'ido detection module';

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
	my ($ido_config_path, $ido_config, $ido_version);

	# try to find a running ido process
	$msg->verbose("Try to find a running ido process");
	$result = $hlp->getProcessByName('ido2db -c');
	
	# do we have a running process?
	if (my $ido_process = (keys %{$result})[0]) {
		$dcy->store('ido_process', $result);

		# find ido.cfg
		my @val = split(/\s+/, $ido_process);
		foreach(@val) { $ido_config_path = $_ if $_ =~ /ido2db.cfg/; }

		# we have a process? fine... save the ido version!
		my $ido_binary = (split(/\s+/, $ido_process))[0];
		@result = $hlp->execCMD("$ido_binary -V");
		foreach(@result) { $ido_version = $_ if $_ =~ /^IDO2DB\s+[0-9\.]+/; }
		$dcy->store('ido_version', $ido_version);
	} else {
		# we do not have a running process
		# try to find it on the hard way...
		$msg->verbose("Can't find ido2db.cfg by running process; try by search the filesystem");

		# create an array with all search paths (from config and cli options)
		my @search_paths = split(/\s*,\s*/, $cfg->{ido}->{searchPaths});
		my @option_paths = split(/\s*,\s*/, $opt->{additional}) if defined $opt->{additional};
		foreach(@option_paths) { push(@search_paths, $_); }

		# search in each path
		foreach(@search_paths) {
			@result = $hlp->find('ido2db.cfg', $_);
			$ido_config_path = $result[0] if defined $result[0];
			last if defined $result[0];
		}
	}

	# save ido2db.cfg
	if (defined $ido_config_path) {
		$dcy->store('ido_config_path', $ido_config_path);
		@result = $hlp->execCMD("cat $ido_config_path | grep -v \\# | sort | uniq");

		if ($result[0] == 0 && defined $result[1]) {
			# remove non-ido lines from result
			splice @result, 0, 2;
	
			# re-sort config lines
			foreach(@result) {
				my ($name, $value) = (split(/\s*=\s*/, $_))[0,1];
				$ido_config->{$name} = $value if defined $value;
			}
	
			$dcy->store('ido_config', $ido_config);
		} else {
			$msg->warning("Found $ido_config_path, but was not able to get it");
		}
	} else {
		$msg->warning("There's no running ido and i can't find ido2db.cfg manually -> skip module $pkg->{name}");
	}

	# ido writes to a mysql on the same host?
	if (defined $ido_config->{db_host}) {
	if ($ido_config->{db_host} eq 'localhost' || $ido_config->{db_host} eq '127.0.0.1') {
		# then get the mysql process too
		$msg->verbose("IDO's MySQL server is on the same host. Save too.");
	        $result = $hlp->getProcessByName('mysqld');
		$dcy->store('mysqld', $result);
	}
	}
}

1;
