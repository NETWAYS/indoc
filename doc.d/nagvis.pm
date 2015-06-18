# File is Part of inDoc, (c) 2015 NETWAYS GmbH
# Licensed unter the Terms of GPL2+

package nagvis;

# includes
use lib qw(lib ../lib .. doc.d);
use strict;
use File::Basename;
use inDoc::ConfigReader;

# package information
our $pkg;
$pkg->{name}        = 'nagvis';
$pkg->{version}     = '0.1';
$pkg->{description} = 'nagvis detection module';

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
	my ($nagvis_config_path, $nagvis_config);

	# find nagvis.ini.php, therefore...
	# create an array with all search paths (from config and cli options)
	my @search_paths = split(/\s*,\s*/, $cfg->{nagvis}->{searchPaths});
	my @option_paths = split(/\s*,\s*/, $opt->{additional}) if defined $opt->{additional};
	foreach(@option_paths) { push(@search_paths, $_); }

	# search in each path
	foreach(@search_paths) {
		@result = $hlp->find('nagvis.ini.php', $_);
		$nagvis_config_path = $result[0] if defined $result[0];
		last if defined $result[0];
	}

	# save nagvis.ini.php data
	if (defined $nagvis_config_path) {
		$dcy->store('nagvis_config_path', $nagvis_config_path);
		@result = $hlp->execCMD("cat $nagvis_config_path | grep -v \\;");
		if ($result[0] == 0) {
			# remove non-icinga lines from result
			splice @result, 0, 1;
	
			# re-sort config lines
			my $heading;
			foreach(@result) {
				# don't save empty lines
				if ($_ ne '') {
					if ($_ =~ /^\[/) {
						$heading = $_;
					} else {
						my ($name, $value) = (split(/\s*=\s*/, $_))[0,1];
						$value =~ s/\"//g;
						$nagvis_config->{$heading}->{$name} = $value;
					}
				}
			}

			$dcy->store('nagvis_config', $nagvis_config);
		} else {
			$msg->warning("Found $nagvis_config_path, but was not able to get it");
		}
	} else {
		$msg->warning("Can't find nagvis.ini.php -> skip module $pkg->{name}");
	}
	
#	# at the end, save log
#        $hlp->saveFile($pnp_config->{log_file}) if -e $pnp_config->{log_file};
}

1;
