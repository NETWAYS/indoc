# File is Part of inDoc, (c) 2015 NETWAYS GmbH
# Licensed unter the Terms of GPL2+

package indoc_base;

# includes
use lib qw(lib ../lib .. doc.d);
use strict;
use File::Basename;
use inDoc::ConfigReader;

# package information
our $pkg;
$pkg->{name}        = 'indoc_base';
$pkg->{version}     = '0.1';
$pkg->{description} = 'indoc base detection module';

# map variables from inDoc.pm --> easier handling and typing
my $msg = $inDoc::msg;
my $cfg = $inDoc::cfg;
my $dcy = $inDoc::discovery;
my $hlp = $inDoc::helper;

# get and merge config
my $moduleConfig = inDoc::ConfigReader->new();
$moduleConfig->load($inDoc::basedir.'/'.dirname(__FILE__).'/'.$pkg->{name}.'.ini');
$cfg = { %$cfg, %$moduleConfig };

sub run {
	# detect some general information about the server
	my (@result, $result);

	# date
        @result = $hlp->execCMD('date');
        $dcy->store('timestamp', $result[1]);

	# uname
	@result = $hlp->execCMD('uname -a');
	$dcy->store('uname', $result[1]);

	# hostname
	@result = $hlp->execCMD('hostname');
	$dcy->store('hostname', $result[1]);

	# fqdn
	@result = $hlp->execCMD('hostname -f');
	$dcy->store('fqdn', $result[1]);

	# OS type and version
	$result = $hlp->getOSType();
	$dcy->store('operating_system', $result);

	# memory
	$result = $hlp->getMemoryStatus();
	$dcy->store('memory', $result);
}

1;
