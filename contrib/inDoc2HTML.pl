#!/usr/bin/perl -w

# File is Part of inDoc, (c) 2015 NETWAYS GmbH
# Licensed unter the Terms of GPL2+

=head1 NAME

inDoc2HTML.pl - Convert inDoc discovery data to HTML

=head1 SYNOPSIS

inDoc2HTML.pl	-i <input file>
		-o <output file>
		[-h]
		[-V]

Convert inDoc discovery data to HTML

=head1 OPTIONS

=over

=item -i|--input <input file>

inDoc XML input file

=item -o|--output <output file>

HTML output file

=item -h|--help

print help page

=item -V|--version

print program version

=cut

# includes
use strict;
use Getopt::Long qw(:config no_ignore_case bundling);
use Pod::Usage;
use XML::Simple;
use Data::Dumper;

# inDoc includes
use lib qw(lib ../lib .. doc.d);
use inDoc::Output::XML;

# version string
my $version = '0.1';

# get command-line parameters
our $opt;
GetOptions(
	"i|input=s"	=> \$opt->{inputFile},
	"o|output=s"	=> \$opt->{outputFile},
	"h|help"	=> \$opt->{help},
	"V|version"	=> \$opt->{version}
);

# should print version?
if (defined $opt->{version}) { print $version."\n"; exit 0; }

# should print help?
if ($opt->{help}) { pod2usage(1); }
if (!$opt->{inputFile} || !$opt->{outputFile}) { pod2usage(1); }

# check files
if (!-r $opt->{inputFile}) {
	print "Input file '$opt->{inputFile}' not readable!";
	exit 1;
}
if (!-w $opt->{outputFile}) {
	print "Output file '$opt->{ouputFile}' not writeable!";
	exit 1;
}

# read file
my $data = XMLin($opt->{inputFile});

# convert xml content into a hashref
$data = inDoc::Output::XML::XML2Hash($data);

# clean unnecessary levels / items
$data = inDoc::Output::XML::HashClean($data);

# convert hash to html
my $HTML;
$HTML .= "<html>\n";
$HTML .= "<head>\n";
$HTML .= "<title>inDoc discovery data from $data->{created}</title>\n";
$HTML .= "<style>\n";
$HTML .= "   body {\n";
$HTML .= "      font-family: Helvetica, Verdana, Arial;\n";
$HTML .= "      font-size: 14px;\n";
$HTML .= "   }\n";
$HTML .= "   .line, .head { height: 30px;}\n";
$HTML .= "   .head { font-weight: bold; }\n";
$HTML .= "   .spacer { margin-left: 50px; }\n";
$HTML .= "</style>\n";
$HTML .= "</head>\n";
$HTML .= "<body>\n";
$HTML .= "<div class='head'>Created on: $data->{created}</div>\n";	delete $data->{created};
$HTML .= "<div class='head'>User: $data->{username}</div>\n";		delete $data->{username};
$HTML .= BuildIndex($data);
$HTML .= Hash2HTML($data, );
$HTML .= "</body>\n";
$HTML .= "</html>\n";

# write output file
open (FILE, ">", $opt->{outputFile}) or die $!;
print FILE $HTML;
close(FILE);

sub BuildIndex {
	my $data = shift;
	my $html;

	$html .= "<div class='head'>Discovered modules:</div>\n";
	$html .= "<div class='spacer'>\n";
	foreach my $val (sort keys %{$data}) {
		$html .= "<div class='line'><a href='#$val'>$val</a></div>\n";
	}
	$html .= "</div>\n";
}

sub Hash2HTML {
	my $data = shift;
	my $html = shift;

	foreach my $val (sort keys %{$data}) {
		if ($data->{$val} =~ /^HASH/) {
#			$html .= "<li>$val</li>\n";
#			$html .= "<ul>\n";
#			$html = Hash2HTML($data->{$val}, $html);
#			$html .= "</ul>\n";

			$html .= "<hr>\n";
			$html .= "<div class='head'><a id='$val'>$val</a></div>\n";
			$html .= "<div class='spacer'>\n";
			$html = Hash2HTML($data->{$val}, $html);
			$html .= "</div>\n";
		} else {
#			$html .= "<li>$val => $data->{$val}</li>\n";
			$html .= "<div class='line'>$val => $data->{$val}</div>\n";
		}
	}

	return $html;
}
