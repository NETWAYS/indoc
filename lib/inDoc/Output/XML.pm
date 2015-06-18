# File is Part of inDoc, (c) 2015 NETWAYS GmbH
# Licensed unter the Terms of GPL2+

package inDoc::Output::XML;

# includes
use strict;

BEGIN {
	unshift @INC, '.';
	unshift @INC, 'lib/';
}

sub new {
	my $class = shift;
	my $self = {};

	bless $self, $class;
	return $self;
}

sub convert {
	my $class = shift;
	my $self = shift;
	my $data;

	$data .= "<indoc created=\"".localtime(time())."\" username=\"".getpwuid( $< )."\">\n";
	$data .= Hash2XML(0, $self);
	$data .= "</indoc>\n";

	return $data;
}

sub Hash2XML {
	my $level = shift;
	my $hash  = shift;
	my $cfg   = $inDoc::cfg;
	my $data;

	$level++;

	foreach my $val (keys %{$hash}) {
		my $save_val = XMLencode($val);
		my $save_hashval = XMLencode($hash->{$val});

		if ($hash->{$val} && ref($hash->{$val}) eq 'HASH') {
			my $tabs = $level; while ($tabs > 0) { $data .= "\t"; $tabs--; }
			$data .= "<level name=\"$save_val\">\n";

			$data .= Hash2XML($level, $hash->{$val});

			$tabs = $level; while ($tabs > 0) { $data .= "\t"; $tabs--; }
			$data .= "</level>\n";
		} else {
			my $tabs = $level; while ($tabs > 0) { $data .= "\t"; $tabs--; }
			if (!$save_hashval && $save_hashval !~ /^-?\d+\.?\d*$/) {
				$save_hashval = '-';
			}
			$data .= "<item name=\"$save_val\" value=\"$save_hashval\" />\n"
		}
	}

	return $data if defined $data;
}

sub XML2Hash {
	my $data = shift;
	my $hashref;

	foreach my $val (keys %{$data}) {
		if ($val eq 'level' || $val eq 'item') {
			if ($val eq 'item') {
				if ($data->{$val}->{value}) {
					$hashref->{$data->{$val}->{name}} = $data->{$val}->{value};
				} else {
					foreach my $val2 (keys %{$data->{$val}}) {
						$hashref->{$val2} = $data->{$val}->{$val2}->{value};
					}
				}
			}

			if ($val eq 'level') {
				foreach my $val2 (keys %{$data->{$val}}) {
					if ($val2 ne 'name') {
						my $tmp = XML2Hash($data->{$val}->{$val2});
						$hashref->{$val2} = $tmp;
					}
				}
			}
		} else {
			if ($data->{$val} =~ /HASH/) {
				if ($data->{$val}->{value}) {
					$hashref->{$val} = $data->{$val}->{value};
				} else {
					my $tmp = XML2Hash($data->{$val});
					$hashref->{$val} = $tmp;
				}
			} else {
				$hashref->{$val} = $data->{$val};
			}
		}
	}

	return $hashref;
}

sub XMLencode {
	my $data = shift;

	if ($data) {
		$data =~ s/\&/&#38;/g;
		$data =~ s/\$/&#36;/g;
		$data =~ s/\|/&#124;/g;
		$data =~ s/\'/&#39;/g;
		$data =~ s/\"/&#34;/g;
		$data =~ s/</&#60;/g;
		$data =~ s/>/&#62;/g;
		$data =~ s/\~/&#126;/g;
		$data =~ s/\`/&#900;/g;
		$data =~ s/\!/&#33;/g;
		$data =~ s/\%/&#37;/g;
		$data =~ s/\^/&#94;/g;
		$data =~ s/\*/&#42;/g;
		$data =~ s/\?/&#63;/g;
		$data =~ s/,/&#44;/g;
		$data =~ s/\(/&#40;/g;
		$data =~ s/\)/&#41;/g;
	}

	return $data;
}

sub HashClean {
	my $data = shift;

        foreach my $val (keys %{$data}) {
                if ($data->{$val} =~ /HASH/) {
                        if ($val eq 'item' || $val eq 'level') {
                                foreach my $val2 (keys %{$data->{$val}}) {
                                        $data->{$val2} = $data->{$val}->{$val2};
                                }
                        }

                        $data->{$val} = HashClean($data->{$val});
                        delete($data->{level}) if $data->{level};
                        delete($data->{item}) if $data->{item};
                }
        }

        return $data;
}

1;
