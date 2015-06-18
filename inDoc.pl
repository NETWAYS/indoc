#!/usr/bin/perl -w

# COPYRIGHT:
# 
# This software is Copyright (c) 2015 NETWAYS GmbH, <support@netways.de>
#
# (Except where explicitly superseded by other copyright notices)
#
# LICENSE:
#
# Copyright (c) 2015 NETWAYS GmbH <support@netways.de>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2+ of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
# or see <http://www.gnu.org/licenses/>.
#
# CONTRIBUTION SUBMISSION POLICY:
#
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of
# the GNU General Public License and is only of importance to you if
# you choose to contribute your changes and enhancements to the
# community by submitting them to NETWAYS GmbH.)
#
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with
# this Software, to NETWAYS GmbH, you confirm that
# you are the copyright holder for those contributions and you grant
# NETWAYS GmbH a nonexclusive, worldwide, irrevocable,
# royalty-free, perpetual, license to use, copy, create derivative
# works based on those contributions, and sublicense and distribute
# those contributions and any derivatives thereof.

=head1 NAME

inDoc.pl - Discover your monitoring environment

=head1 SYNOPSIS

inDoc.pl        [-o <output dir>]
                [-a <path1,path2,path2>]
		[-i <module1,module2>]
                [-e <module1,module2>]
                [-l]
                [-h]
                [-v]
                [-V]

Discover your monitoring environment

=head1 OPTIONS

=over

=item -o|--output <output dir>

Output dir

=item -a|--additional <path1,path2,path3>

Specify a comma seperated list of full qualified paths for inDoc discoveries. It's helpfull if your monitoring environment runs in a custom path like '/opt/monitoring-foo'.

=item -i|--include <module1,module2,module3>

Specify a comma seperated list of modules you want to run for discovery

=item -e|--execlude <module1,module2,module3>

Specify a comma seperated list of modules you don't want to run during discovery

=item -l|--list

List all available modules

=item -h|--help

print help page

=item -v|--verbose

Verbose mode. Output will be printed to STDOUT

=item -V|--version

print program version

=cut

# basic perl includes
use strict;
use Getopt::Long qw(:config no_ignore_case bundling);
use Pod::Usage;

# inDoc includes
use lib qw(lib ../lib .. doc.d);
use inDoc;

# version string
my $version = '0.1';

# get command-line parameters
our $opt;
GetOptions(
	"o|output=s"    => \$opt->{outputDir},
	"a|additional=s"=> \$opt->{additional},
	"i|include=s"	=> \$opt->{include},
	"e|exclude=s"	=> \$opt->{exclude},
	"l|list"        => \$opt->{list},
	"h|help"        => \$opt->{help},
	"v|verbose:s"   => \$opt->{verbose},
	"V|version"     => \$opt->{version}
);

# should print version?
if (defined $opt->{version}) { print $version."\n"; exit 0; }

# should print help?
if ($opt->{help}) { pod2usage(1); }

# run
inDoc::Run($opt);
