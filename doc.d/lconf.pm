# File is Part of inDoc, (c) 2015 NETWAYS GmbH
# Licensed unter the Terms of GPL2+

package lconf;

# includes
use lib qw(lib ../lib .. doc.d);
use strict;
use File::Basename;
use inDoc::ConfigReader;

# package information
our $pkg;
$pkg->{name}        = 'lconf';
$pkg->{version}     = '0.1';
$pkg->{description} = 'lconf detection module';

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
	my ($LConfExportPath, $LConfConfigPath);

	# try to find LConfExport; therefore....
	# create an array with all search paths (from config and cli options)
	my @search_paths = split(/\s*,\s*/, $cfg->{lconf}->{searchPaths});
	my @option_paths = split(/\s*,\s*/, $opt->{additional}) if defined $opt->{additional};
	foreach(@option_paths) { push(@search_paths, $_); }

	# and search in each path
	foreach(@search_paths) {
		@result = $hlp->find('LConfExport.pl', $_);
		$LConfExportPath = $result[0] if defined $result[0];
		last if defined $result[0];
	}

	# LConfExport found?
	if (defined $LConfExportPath) {
		$dcy->store('LConfExport.pl', $LConfExportPath);
		# get dir to config.pm
		@result = $hlp->execCMD("grep 'use lib' $LConfExportPath | grep -i etc");
		my $LConfConfigPath = (split(/[\'\"]/, $result[1]))[1].'/config.pm';

		# save LConf's config.pm
		if (defined $LConfConfigPath) {
			$dcy->store('config.pm', $LConfConfigPath);
			@result = $hlp->execCMD("cat $LConfConfigPath | grep -v \\# | grep '\\".'$'."cfg'");
			
			# save config
			if ($result[0] == 0) {
				my $LConfConfig; shift(@result);
				foreach(@result) {
					my ($name, $value) = (split(/\s+=\s+/, $_))[0,1];
					$LConfConfig->{$name} = $value;
				}

				$dcy->store('LConfConfig', $LConfConfig);
			}
		}

		# get dir to config.pm
		@result = $hlp->execCMD("grep '^my ".'$'."version' $LConfExportPath");
		if ($result[0] == 0) {
			my $LConfVersion = (split(/\s+=\s+/, $result[1]))[1];
			$dcy->store('LConfVersion', $LConfVersion);
		}
	} else {
		$msg->warning("No LConf installation found -> skip module $pkg->{name}");
	}
}

1;
