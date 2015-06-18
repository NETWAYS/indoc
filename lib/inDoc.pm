# File is Part of inDoc, (c) 2015 NETWAYS GmbH
# Licensed unter the Terms of GPL2+

package inDoc;

=head1 NAME

inDoc - the core module

=head1 DESCRIPTION

The inDoc core module is the main handler.

It provides a message handler, configuration and some discovery, helper and output functions.

=cut

# includes 
use strict;
use Cwd;

# inDoc includes
use lib qw(lib ../lib .. doc.d);
use inDoc::MessageHandler;
use inDoc::ConfigReader;
use inDoc::Discovery;
use inDoc::Helper;
use inDoc::Output;

BEGIN {
        unshift @INC, '.';
        unshift @INC, 'lib/';
}

sub Run {
	# prepare global vars
	our $opt       = shift;
	our $basedir   = Cwd::realpath('.');
	our $msg       = inDoc::MessageHandler->new();		# this var will handle all messages (info, warning, error, verbose)
	our $cfg       = inDoc::ConfigReader->new();		# create config store
	our $discovery = inDoc::Discovery->new();		# set up discovery
	our $helper    = inDoc::Helper->new();			# prepare helper functions
	
	# load main config
	$cfg->load($basedir.'/etc/inDoc.ini');

	# just list modules?
	$discovery->listModules() if $opt->{list};

	# user has specified a different output dir?
	$cfg->{global}->{outputDir} = $opt->{outputDir} if defined $opt->{outputDir};

	# create output dir
        if (!-e $cfg->{global}->{outputDir}) {
                my $result = `mkdir $cfg->{global}->{outputDir} 2>&1`;
                (defined($result) && $result ne '')
                        ? $msg->error("Create output directory '$cfg->{global}->{outputDir}' failed: $result")
                        : $msg->info("Create output directory '$cfg->{global}->{outputDir}'");
        } else {
                $msg->warning("Output directory '$cfg->{global}->{outputDir}' already exists.");
        }

	# run modules
	$discovery->run();
	
	# prepare output handler with discovery result
	my $output = inDoc::Output->new($discovery->get());
	
	# write converted output per module to output folder
	$output->write();

	# write one big 'indoc' file (if someone wants an easier handling with one file)
	$output->writeOneFile();
}

1;
