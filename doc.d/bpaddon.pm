# File is Part of inDoc, (c) 2015 NETWAYS GmbH
# Licensed unter the Terms of GPL2+

package bpaddon;

# includes
use lib qw(lib ../lib .. doc.d);
use strict;
use File::Basename;
use inDoc::ConfigReader;

# package information
our $pkg;
$pkg->{name}        = 'bpaddon';
$pkg->{version}     = '0.1';
$pkg->{description} = 'bpaddon detection module';

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
	my $bp_config_path;

	# try to find nagios-bp.conf
	# create an array with all search paths (from config and cli options)
	my @search_paths = split(/\s*,\s*/, $cfg->{bpaddon}->{searchPaths});
	my @option_paths = split(/\s*,\s*/, $opt->{additional}) if defined $opt->{additional};
	foreach(@option_paths) { push(@search_paths, $_); }

	# search in each path
	foreach(@search_paths) {
		@result = $hlp->find('nagios-bp.conf', $_);
		$bp_config_path = $result[0] if defined $result[0];
		last if defined $result[0];
	}

	# save bpaddon data
	if (defined $bp_config_path) {
		$dcy->store('bp_config_path', $bp_config_path);

		# get path of bp config
		my @tmp = split('/', $bp_config_path); pop(@tmp);
		my $bp_config_dir = join('/', @tmp);

		# we have the right directory; save ndo.cfg and settings.cfg
		my $bp_ndo_cfg;
		@result = $hlp->execCMD("cat $bp_config_dir/ndo.cfg | grep -v \\# | sort | uniq");
		if ($result[0] == 0) {
			# remove return code from result
			splice @result, 0, 1;
	
			# re-sort config lines
			foreach(@result) {
				my ($name, $value) = (split(/\s*=\s*/, $_))[0,1];
				$bp_ndo_cfg->{$name} = $value if defined $value;
			}

			$dcy->store('ndo.cfg', $bp_ndo_cfg);
		}

		my $bp_settings_cfg;
		@result = $hlp->execCMD("cat $bp_config_dir/settings.cfg | grep -v \\# | sort | uniq");
		if ($result[0] == 0) {
			# remove return code from result
			splice @result, 0, 1;

			# re-sort config lines
			foreach(@result) {
				my ($name, $value) = (split(/\s*=\s*/, $_))[0,1];
				$bp_settings_cfg->{$name} = $value if defined $value;
			}

			$dcy->store('settings.cfg', $bp_settings_cfg);
		}

		# do we now path to 'settings.pm' from 'settings.cfg'?
		# if yes, we can search for the bpaddon version...
		if ($bp_settings_cfg && $bp_settings_cfg->{'NAGIOSBP_LIB'}) {
			# this is mega super duper dirty, but there's no other way :(
			@result = $hlp->execCMD("cat ".$bp_settings_cfg->{'NAGIOSBP_LIB'}."/settings.pm | grep -i \"^sub getVersion\" | awk -F '".'"'."' '{print \$2}'");
			$dcy->store('bp_version', $result[1]) if $result[1] =~ /[0-9\.]+/;
		}
	} else {
		$msg->warning("Can't find nagios-bp.conf -> skip module $pkg->{name}");
	}
}

1;
