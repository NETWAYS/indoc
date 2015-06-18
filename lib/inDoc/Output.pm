# File is Part of inDoc, (c) 2015 NETWAYS GmbH
# Licensed unter the Terms of GPL2+

package inDoc::Output;

# includes
use strict;
use inDoc::Output::XML;

BEGIN {
	unshift @INC, '.';
	unshift @INC, 'lib/';
}

sub new {
	my $class = shift;
	my $self = shift;

	bless $self, $class;
	return $self;
}

sub dump {
	my $class = shift;
	print $class->{output}."\n";
}

sub write {
	my $class = shift;
	my $cfg   = $inDoc::cfg;
	my $msg   = $inDoc::msg;

	# process one file per discovery module
	foreach my $module (keys %{$class}) {
		my $data = convert($cfg->{global}->{outputFormat}, $module, $class->{$module});
		my $file = $cfg->{global}->{outputDir}.'/'.$module.'.'.$cfg->{global}->{outputFileExtension};

		$msg->info("Write discovery data for module '$module' to '$file'");
		open(FH, ">$file");
		print FH $data;
		close(FH);
	}
}

sub writeOneFile {
	my $class = shift;
	my $cfg   = $inDoc::cfg;
	my $msg   = $inDoc::msg;

	# convert data to xml
	my $data = convert($cfg->{global}->{outputFormat}, 'indoc', $class);

	# write file
	my $file = $cfg->{global}->{outputDir}.'/inDoc.'.$cfg->{global}->{outputFileExtension};
	$msg->info("Write discovery data to global file '$file'");
	open(FH, ">$file");
	print FH $data;
	close(FH);
}

sub convert {
	my $outputFormat = shift;
	my $moduleName   = shift;
	my $moduleData   = shift;

	if ($outputFormat eq 'XML') {
		my $XML = inDoc::Output::XML->new();
		$XML->convert($moduleData);
	}
}

1;
