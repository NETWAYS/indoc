# File is Part of inDoc, (c) 2015 NETWAYS GmbH
# Licensed unter the Terms of GPL2+

package check_disk;

# includes
use lib qw(lib ../lib .. doc.d);
use strict;
use File::Basename;
use inDoc::ConfigReader;

# package information
our $pkg;
$pkg->{name}        = 'check_disk';
$pkg->{version}     = '0.1';
$pkg->{description} = 'plugin check_disk detection module';

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
	# define vars
	my ($plugin_path);

	# get path to objects.cache
	my $tmp = $dcy->get('icinga');
	my $objects_cache =  $tmp->{icinga}->{icinga_config}->{object_cache_file};

	# do we have permission to access objects.cache?
	if (defined $objects_cache && -f $objects_cache) {
		# get command from objects.cache
		my $check_commands;
		my @result = $hlp->execCMD("cat $objects_cache | grep -A 3 -i '^define command'");
		for (my $i=0; $i<@result;++$i) {
			if ($result[$i] =~ /command_line/ && $result[$i] =~ /$pkg->{name} /) {
				my $command_name = (split(/\s+/, $result[$i-1]))[2];
				my $command_line = (split(/\s+/, $result[$i], 3))[2];
	
				$check_commands->{$command_name} = $command_line;
			}
		}
		$dcy->store('check_commands', $check_commands);
	}

	# try to find plugin (therefore create an array with all search paths (from config and cli options))
	my @search_paths = split(/\s*,\s*/, $cfg->{$pkg->{name}}->{searchPaths});
	my @option_paths = split(/\s*,\s*/, $opt->{additional}) if defined $opt->{additional};
	foreach(@option_paths) { push(@search_paths, $_); }
	
	# search plugin in each path
	foreach(@search_paths) {
		my @result = $hlp->find($pkg->{name}, $_);
		$plugin_path = $result[0] if defined $result[0];
	}

	if ($plugin_path) {
		$dcy->store('plugin_path', $plugin_path);

		# get plugins file statistic
		my $result = $hlp->getFileStat($plugin_path);
		$dcy->store('file_stats', $result);
	} else {
		$msg->warning("Can't find plugin -> skip module $pkg->{name}");
	}
}

1;
