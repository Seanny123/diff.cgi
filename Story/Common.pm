package Story::Common;

################ Copyright ################

# This program is Copyright 2011 by Ben Hildred.
# This program is free software; you can redistribute it and/or
# modify it under the terms of the Perl Artistic License or the
# GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# If you do not have a copy of the GNU General Public License write to
# the Free Software Foundation, Inc., 675 Mass Ave, Cambridge,
# MA 02139, USA.

################ Module Preamble ################

use 5.004;

use strict;
use warnings;
use warnings::register;
use Carp;
use Exporter qw(import);
use Story::Config;
use open ':encoding(utf8)';
binmode(STDOUT, ':utf8');
binmode(STDIN, ':utf8');

our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
$VERSION = sprintf "%d.%03d", q$Revision: 1.3 $ =~ /(\d+)/g;

@ISA	= qw(Exporter);
@EXPORT = qw(
	smkdir
	super_e
	systemp
	systemp2
	systemp3
	move
	movenew
	moveset
	ltime
	vdiff
	mount
	umount
	xtermh1
	xtermhp
	bt
	mount_avail
);
%EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],
@EXPORT_OK   = qw();

###############
#	      #
# Subroutines #
#	      #
###############

sub systemp(@);
sub systemp2(@);
sub move($$);
sub movenew($$);
sub moveset($$$);
sub super_e(@);
sub smkdir($);
sub ltime($);
sub vdiff(@);
sub mount;
sub umount();
sub xtermh1($);
sub xtermhp($);
sub bt(@);
sub prepfshash();
sub mount_avail();

###########################
#			  #
# Data Structure Varables #
#			  #
###########################


##################
#		 #
# Other Varables #
#		 #
##################

my $cfg=new Story::Config 'main';
our $tout =0;
our $touth;
open $touth, '>', '/dev/tty' and $tout++;
if($tout){my $oldfh = select(STDERR); $| = 1; select($touth); $| = 1; select($oldfh);}

#######################
#		      #
# Lexical Subroutines #
#		      #
#######################


###############
#	      #
# Subroutines #
#	      #
###############

sub xtermhp($){
	return undef unless $tout;
	die unless $touth;
	return print {$touth} xtermh1(shift);
}

sub xtermh1($){
	return "\033]0;".$_[0]."\07";
}

{
	my %fshash;
	my @mounts;
	sub mount_avail(){
		prepfshash unless %fshash;
		return keys %fshash;
	}
	sub prepfshash(){
		my $fh;
		local $_;
		open $fh, '<', '/etc/fstab';
		while(<$fh>){
			next if /^[	 ]*$/;
			next if /^[	 ]*#/;
			my @f=split;
			warn 'a' unless defined $f[0];
			$f[0]=~s!^UUID=!/dev/disk/by-uuid/!;
			$fshash{$f[1]}=$f[0];
		}
		open $fh, '<', '/etc/mtab';
		while(<$fh>){
			next if /^[	 ]*$/;
			next if /^[	 ]*#/;
			my @f=split;
			warn 'a' unless defined $f[0];
			undef $fshash{$f[1]} if(defined$fshash{$f[1]}&& $fshash{$f[1]}eq$f[0]);
		}
	}
	sub mount{
		my $_;
		my $ret=0;
		prepfshash unless %fshash;
		foreach(@_){
			next unless(-e $fshash{$_});
			my $ret2;
			if($ret2=system(qw(mount), $_)){ #negitive return
				$ret+=$ret2;
			}else{
				push @mounts,$_;
			}
		}
		return $ret;
	}
	sub umount(){
		my $ret=0;
		foreach(@mounts){
			$ret+=system(qw(umount), $_) if defined;
			$_=undef;
		}
		return $ret;
	}
}

sub systemp(@){
	use Scalar::Util qw(tainted);
	warnings::warnif 'param tainted' if grep {tainted($_)} @_;
	print join ' ', @_ if $cfg->debug;
	print(($cfg->html?'<br/>':''),"\n") if $cfg->debug;
	if($cfg->debug){
		my $ret = system { $_[0] } @_;
		if ($? == -1) {
			carp "failed to execute: $!";
		}elsif ($? & 127) {
			carp sprintf "child died with signal %d, %s coredump", ($? & 127),  ($? & 128) ? 'with' : 'without';
		}elsif($? >> 8) {
			carp sprintf "child exited with value %d", $? >> 8;
		}elsif($?) {
			warn $ret if $ret;
		}
		return $?;
	}else{
		return system { $_[0] } @_;
	}
}
sub systemp2(@){
	local *STDIN;
	open STDIN, '<', '/dev/null' or die;
	systemp @_;
}

sub systemp3(@){
	local *STDIN;
	local *STDOUT;
	local *STDERR;
	open STDIN, '<', '/dev/null' or die;
	open STDOUT, '>', '/dev/null' or die;
	open STDERR, '>', '/dev/null' or die;
	systemp @_;
}

sub smkdir($){
	my $x=shift;
	if(-d $x){
		return;
	}elsif(-e $x){
		die;
	}else{
		return system qw(mkdir), $x;
	}
}

sub move($$){
	use Scalar::Util qw(tainted);
	my $y=shift;
	warnings::warnif 'y tainted' if tainted($y);
	my $z=shift;
	warnings::warnif 'z tainted' if tainted($z);
	if(-d $z){
		return system qw(mv -i), $y, $z;
	}elsif(! -e $z){
		return system qw(mv -i), $y, $z;
	}elsif(-l $z){
		return system 'rm', $z;
	}elsif(!system qw(/usr/local/bin/diff-q -w -s), $y, $z){
		return system qw(rm), $z;
	}else{
		return vdiff $y, $z;
	}
}

sub movenew($$){
	use Scalar::Util qw(tainted);
	my $y=shift;
	warnings::warnif 'y tainted' if tainted($y);
	my $z=shift;
	warnings::warnif 'z tainted' if tainted($z);
	if(-d $z){
		return system qw(mv -i), $y, $z;
	}elsif(! -e $z){
		return system qw(mv -i), $y, $z;
	}elsif(-l $z){
		return system 'rm', $z;
	}elsif(!system qw(/usr/local/bin/diff-q -w -s), $y, $z){
		return system qw(rm), $z;
	}else{
		my $a = bt(qw(grep noscript), $y); ###
		my $b = bt(qw(grep noscript), $z);
		chomp $a;
		return 1 if($a=~m'$.*^'ms);
		chomp $b;
		return 1 if($b=~m'$.*^'ms);
		print $a,$b;
		if($a lt $b){
			print "first\n";
			return system 'rm', $y;
		}elsif($a gt $b){
			print "second\n";
			return system 'rm', $z;
		}elsif($a eq $b){
			print "match\n";
			return vdiff $y, $z;
		}
		return 1;
	}
}

sub moveset($$$){
	my $y=shift;
	my $z=shift;
	my $x=shift;
	if(! -e $z){
		system qw(setfattr -n user.mime_type -v), $x, $y;
		return system qw(mv -i), $y, $z;
	}elsif(-l $z){
		return system 'rm', $z;
	}elsif(!system qw(/usr/local/bin/diff-q -w -s), $y, $z){
		return system qw(rm), $z;
	}else{
		warn $z;
		return 1;
	}
}

sub ltime($){
	use POSIX qw(strftime);

	return strftime "%e-%b-%Y", localtime shift;
	return strftime "%e-%b-%Y %H:%M", localtime shift;
	return strftime "%a %b %e %H:%M:%S %Y", localtime shift;
}

sub super_e(@){
	return grep {-e} @_;
}

warnings::register_categories(qw(exec));
sub vdiff(@){
	my $e=$cfg->execute;
	my @arg = (grep {m/\.wmv$/} @_)?'-b':();
	if(warnings::fatal_enabled()){
		warnings::warnif('exec', join ' ', 'vimdiff', @arg, @_);
		return 1 unless $e&3;
	}elsif($e&3){
		warnings::warnif('exec', join ' ', 'vimdiff', @arg, @_);
	}else{
		return 1;
	}

	push @arg, '-c','normal ]c';
	#local STDERR;
	#open STDERR, '>/dev/null';
	system qw(.bin/s3), @_;
	return 1 unless system qw(/usr/local/bin/diff-q), @_;
	if($e&32){
		if(($e&3)==3){$ENV{EDITOR}=join '', 'vim     -g -f',@arg;
		}elsif($e&2 ){$ENV{EDITOR}=join '', 'vimdiff -g -f',@arg;
		}elsif($e&1 ){$ENV{EDITOR}=join '', 'vimdiff',@arg;
		}else{		die "Unexpected code path";
		}
		warn $ENV{EDITOR};
		return !system(qw(sudoedit), @_);
	}else{
		return !system(qw(vim     -g -f), @arg, @_) if ($e&3)==3;
		return !system(qw(vimdiff -g -f), @arg, @_) if $e&2;
		return !system(qw(vimdiff),       @arg, @_) if $e&1;
	}
			#$cfg->execute($q->param('execute')&28)	if($q->param('execute'));	#1	vimdiff
			#									#2	gvimdiff
			#									#4	handle_only
			#									#8	systemp
			#									#16	file
			#									#32	sudo
			#									#64	handle_ident
	return !system((($cfg->execute&32)?qw(sudo):()), qw(vim     -g -f), @arg, @_) if ($e&3)==3;
	return !system((($cfg->execute&32)?qw(sudo):()), qw(vimdiff -g -f), @arg, @_) if $e&2;
	return !system((($cfg->execute&32)?qw(sudo):()), qw(vimdiff),       @arg, @_) if $e&1;
}

sub bt(@){
	my $fh;
	my $ret;
	print join ' ', @_ if $cfg->debug;
	print(($cfg->html?'<br/>':''),"\n") if $cfg->debug;
	open ($fh, '-|', @_) || die 'return undef';
	$ret=join '', <$fh>;
	return $ret;
}

1;

################ Documentation ################
__END__
