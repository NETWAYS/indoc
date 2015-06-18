# File is Part of inDoc, (c) 2015 NETWAYS GmbH
# Licensed unter the Terms of GPL2+

package inDoc::Discovery;

=head1 NAME

inDoc::Discovery - provides inDoc discovery functions

=cut

# includes
use strict;
use Module::Load;

BEGIN {
        unshift @INC, '.';
        unshift @INC, 'lib/';
}



=head2 function: new()

B<< my $discovery = inDoc::Discovery->new(); >>

Create a new disccovery handler object.

=cut

sub new {
	my $class = shift;
	my $self = {};
	bless $self, $class;
}



=head2 function: run()

B<< $discovery->run(); >>

Run inDoc modules.

=cut 

sub run {
	my $class = shift;
	my $msg   = $inDoc::msg;

	# get available modules
	$msg->verbose("Try to find all inDoc modules");
	my @modules = getModules();
	
        # load and run each module
	foreach my $module (@modules) {
		my $name = (split(/\./, $module))[0];
		$msg->info("Run module '$name'");

		load $name;
		$class->{tmp}->{running_module} = $name;

		eval '$name->run()';
	}
}



=head2 function: getModules()

B<< my $modules = $discovery->getModules(); >>

Get a list of all available modules. Function will return an array.

=cut

sub getModules {
	my $moduleDir = $inDoc::basedir.'/'.$inDoc::cfg->{global}->{discoverDir};
	opendir(DIR, $moduleDir) || die $inDoc::msg->error("Can't open dir: $!");
	my @modules = grep { (/^[^.].+\.pm/) && -f $moduleDir.'/'.$_ } readdir(DIR);
	closedir DIR;

	# excludes?
	my $opt = $inDoc::opt;
	my @excludes = split(/\s*,\s*/, $opt->{exclude}) if defined $opt->{exclude};
	if ($#modules >= 1) {
		foreach my $exclude (@excludes) {
			for (my $i = $#modules; $i > -1; $i--) {
				splice @modules, $i, 1 if $modules[$i] =~ /^$exclude/;
			}
		}
	}

	# includes?
	@modules = split(/\s*,\s*/, $opt->{include}) if defined $opt->{include};

	return @modules;
}



=head2 function: listModules()

B<< $discovery->list(); >>

Print a list of all available modules.

=cut

sub listModules {
	my @modules = getModules();

	print "Available modules:\n";
	foreach(@modules) {
		my $module = (split(/\./, $_))[0];
		load $module;
	
		my $pkg = eval('$' . "$module".'::pkg');
		print "\t- ".$module." (".$pkg->{description}.")\n";
	}

	exit 0;
}



=head2 function: store(<name>, <value>)

B<< $discovery->store('foo', 'bar'); >>

Store discovered data 'bar' in a hashref with the key 'foo'.

=cut

sub store {
	my $class = shift;
	my $name  = shift;
	my $value = shift;
	my $msg   = $inDoc::msg;
	my $cfg   = $inDoc::cfg;

	# prepare
	my $called_module = $class->{tmp}->{running_module};
	my @excludeFields = split(/\,[\s]*/, $cfg->{global}->{excludeFields});

	# configured excludes
	if ($value && $value =~ /HASH/) {
		foreach my $val (keys %{$value}) {
			my $search = $val; $search =~ s/\[/\\\[/g; $search =~ s/\]/\\\]/g;
			$value->{$val} = '*******' if grep(/^$search/, @excludeFields);
		}
	}

	# store
	$class->{'data'}->{$called_module}->{$name} = $value;
	$msg->verbose("Module '$called_module' stores '$name'");
}



=head2 function: get()

B<< my $data = $discovery->get() >>

Get stored data as hashref.

=cut

sub get {
	my $class = shift;
	return $class->{data};
}



=head2 function dump()

B<< $discovery->dump(); >>

Print stored data to STDOUT (hashref format)

=cut

sub dump {
	my $class = shift;
	my $self;

	use Data::Dumper;
	print Dumper $class;
}

1;
