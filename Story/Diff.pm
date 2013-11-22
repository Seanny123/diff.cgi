package Story::Diff;

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
use Story::Common;
no warnings qw(exec);

our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
$VERSION = sprintf "%d.%03d", q$Revision: 1.3 $ =~ /(\d+)/g;

@ISA	= qw(Exporter);
@EXPORT = qw(
	dofilter_a
	dofilter_b
	dofilter_c
	ignore_only
	handle_only
	ignore_common
	handle_common
	ignore_diff
	handle_diff
	dont_diff
	handle_skipped
	Header
	footer
);
%EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],
@EXPORT_OK   = qw();

###############
#	      #
# Subroutines #
#	      #
###############

sub Header($;%);
sub footer(;%);
sub ignore_only($$$$);
sub handle_only($$$$);
sub ignore_common($$$$);
sub handle_common($$$$);
sub dont_diff($$$$);
sub ignore_diff($$$$);
sub handle_diff($$$$);
sub handle_skipped($$$$);
sub rmdirl(;@);
sub rmdirl2(;@);
sub path_mangle($$$$$$;$);

##################
#		 #
# Other Varables #
#		 #
##################

my $cfg=new Story::Config 'main';

###############
#	      #
# Subroutines #
#	      #
###############

sub Header($;%){
	my $title=shift;
	my %p=@_;
	my $fh=$p{fh}//*STDOUT;
	my $x=$main::q->param('xml')||0;
	my $cgi=$main::cgi;
	unless($x){
		print $fh CGI::header(
			-status=>200,
			-type=>($cfg->html?'text/html':'text/plain'),
			-charset=>'UTF-8',
			-expires=>'+3s'
		) if $cgi;
		warningsToBrowser($cgi);
		unless($cfg->html||$cgi){
			xtermhp($title) if $title;
			return;
		}
		$main::link{'shortcut icon'}='/favicon.ico';
		my %link=%main::link;
		print $fh CGI::start_html(
			($title?(-title=>$title):()),
			-encoding=>'utf-8',
			($cgi?(-base=>'true'):()),
			-style=>{media=>'screen','src'=>'/css/indexstyle.css'},
			-script=>[
				{-src=>'/javascript/prototype/prototype.js'},
				#{-src=>'https://ajax.googleapis.com/ajax/libs/jquery/1.5.2/jquery.js'},
				#{-src=>'/css/jquery.fixedheadertable.js'},
				{-src=>'/css/story.js'},
			],
			-head=>[map {Link({-rel=>$_,-href=>$link{$_}}),} keys %link],
		);
		if(defined $p{group}){
			print $fh h1($title),"\n";
			#$fhmode++;
			print $fh "<ol><li><ol>\n";
		}elsif(!defined($p{filter})){
			print $fh nav %link, center=>h1($title);
			if($p{main}){
				print $fh $p{main},"\n";
			}
		}elsif($p{filter}eq 1){
			print $fh nav %link, center=>h11($p{uri});
			print $fh row_head_light;
		}elsif($p{filter}eq 2){
			print $fh nav %link, center=>h11($p{uri});
			print $fh restrict '_', $p{pat}, $p{uri} unless $p{count};
			print $fh row_head;
		}elsif($p{filter}){
			print $fh nav %link, center=>h11($p{uri});
			print $fh restrict_filter $p{filter}, $p{pat}, $p{uri} unless $p{count};
			print $fh row_head_filter $p{filter};
		}else{
		}
	}else{
		print CGI::header(
			-status=>200,
			-type=>($cfg->html?'application/'.($x==2?'javascript':'xml'):'text/plain'),
			-charset=>'UTF-8',
			-expires=>'+3s'
		) if $cgi;
	}
}
sub footer(;%){
	my %p=@_;
	my $fh=$p{fh}//*STDOUT;
	my $x=$main::q->param('xml')||0;
	my $cgi=$main::cgi;
	my %link=%main::link;
	if($x==2){
		while(@CGI::Carp::WARNINGS){
			my $msg = shift @CGI::Carp::WARNINGS;
			$msg =~ tr/<>-/\253\273\255/;
			chomp $msg;
			print $fh qq(alert("warning: $msg");\n);
		}
		#print foreach @CGI::Carp::WARNINGS;
		#print "/*\n";warningsToBrowser(1);warningsToBrowser(0);print "*/\n";
		return;
	}elsif($x){
		return;
	}else{
		return unless $cfg->html;
		if(defined $p{group}){
			print $fh q(</ol></li></ol>);
		}elsif(!defined($p{filter})){
			if($p{main}){
				my $m=$p{main}=~s!^<([^ >]+)[ >].*$!</$1>!r;
				print $fh $m;
			}
		}elsif($p{filter}eq 2){
			print $fh row_foot;
			#print $fh restrict '_', $p{pat}, $p{uri} unless $p{count};
		}else{
			print $fh q(</tbody></table>);
		}
		print $fh nav %link if ($cgi);
		if($p{debug}){
			my @klist=sort keys %ENV;
			@klist=grep {!m/^DOCUMENT_ROOT$/} @klist;
			@klist=grep {!m/^SCRIPT_NANE$/} @klist;
			@klist=grep {!m/^GATEWAY_INTERFACE$/} @klist;
			print $fh table({border=>1,width=>'100%',height=>'100px'},Tr([map({td([$_,$ENV{$_}])} @klist)])),;
		}
		print $fh end_html,"\n";
	}
}

sub sysret($$){
	my $a=shift;
	my $b=shift;

	if ($a == -1) {
		return "failed to execute: $b";
	} elsif ($a & 127) {
		return sprintf "child died with signal %d, %s coredump", ($a & 127),  ($a & 128) ? 'with' : 'without';
	} else {
		return sprintf "child exited with value %d", $a >> 8;
	}
}

my %pm;
sub path_mangle($$$$$$;$){
	use Cwd qw(abs_path cwd);
	use Scalar::Util qw(tainted);
	my($ret,$dummy,$ao,$bo)=my($phase,$action,$a,$b,$c,$d,$r)=@_;
	warnings::warnif 'phase tainted' if tainted($phase);
	warnings::warnif 'action tainted' if tainted($action);
	warnings::warnif 'a tainted' if tainted($a);
	warnings::warnif 'b tainted' if tainted($b);
	warnings::warnif 'c tainted' if tainted($c);
	warnings::warnif 'd tainted' if tainted($d);
	warnings::warnif 'r tainted' if tainted($r);

	die unless defined $pm{$phase};
	die unless defined $pm{$phase}{$action};

	if($a =~ m!\.\./!){	$a=abs_path($a)unless($a =~ s!/[^/]+/\.\./!/!);
	}elsif($a =~ m!/\./!){	$a=~s!!/!;
	}elsif($a =~ m!^\./!){	$a=~s!!cwd.'/'!e;
	}			$a=~s!$!/! unless$a=~m!/$!;

	if($b =~ m!\.\./!){	$b=abs_path($b)unless($b =~ s!/[^/]+/\.\./!/!);
	}elsif($b =~ m!/\./!){	$b=~s!!/!;
	}elsif($b =~ m!^\./!){	$b=~s!!cwd.'/'!e;
	}			$b=~s!$!/! unless$b=~m!/$!;

	$a=~s!/home2/!/home/!;
	$ao=~s!/home2/!/home/!;
	$b=~s!/home2/!/home/!;
	$bo=~s!/home2/!/home/!;

	my $ignore=0;
	$ignore+=2 if 'ignore'eq$phase;
	$ignore+=2 if 'diff'eq$phase;
	print $phase.'_'.$action.': a=',$a,',',$ao,';b=',$b,',',$bo,';c=',$c,';d=',$d,($cfg->html?'<br/>':''),"\n" if($cfg->debug>$ignore+1);

	foreach my $sub (@{$pm{$phase}{$action}}){
		$ret = $sub->($ao,$bo,$c,$d);				return$ret if$ret;
		$ret = $sub->($a ,$bo,$c,$d)unless$a eq$ao;		return$ret if$ret;
		$ret = $sub->($ao,$b ,$c,$d)unless$b eq$bo;		return$ret if$ret;
		$ret = $sub->($a ,$b ,$c,$d)unless($a eq$ao||$b eq$bo);	return$ret if$ret;
	}

	my ($co,$do)=($c,$d);
	if($c=~m!./.!){
		$c=~s!^([^/]+/)!!;
		$ret=path_mangle($phase,$action,$ao.$1,$bo.$1,$c,$d,1);
		return$ret if$ret;
	}

	return 0 unless'handle'eq$phase;
	print '# handle_'.$action.': a=',$a,',',$ao,';b=',$b,',',$bo,';c=',$c,';d=',$d,($cfg->html?'<br/>':''),"\n" if($cfg->debug>$ignore);

	return 0 if$r;
	if('diff'eq$action){
		#vdiff $ao.$c.'/'.$d, $bo.$c.'/'.$d;	return 1;
		push @main::vimdiff, $co.'/'.$do;	return 1;
	}elsif('common'eq$action){
		push @main::ident, $_;
	}
	return 0;
}
sub ignore_only($$$$){	 my($a,$b,$c,$d)=@_;path_mangle('ignore','only'   ,$a,$b,$c,$d);}
sub handle_only($$$$){	 my($a,$b,$c,$d)=@_;path_mangle('handle','only'   ,$a,$b,$c,$d);}
sub dont_diff($$$$){	 my($a,$b,$c,$d)=@_;path_mangle('dont'  ,'diff'   ,$a,$b,$c,$d);}
sub handle_skipped($$$$){my($a,$b,$c,$d)=@_;path_mangle('handle','skipped',$a,$b,$c,$d);}
sub ignore_diff($$$$){	 my($a,$b,$c,$d)=@_;path_mangle('ignore','diff'   ,$a,$b,$c,$d);}
sub handle_diff($$$$){	 my($a,$b,$c,$d)=@_;path_mangle('handle','diff'   ,$a,$b,$c,$d);}
sub ignore_common($$$$){ my($a,$b,$c,$d)=@_;path_mangle('ignore','common' ,$a,$b,$c,$d);}
sub handle_common($$$$){ my($a,$b,$c,$d)=@_;path_mangle('handle','common' ,$a,$b,$c,$d);}

$pm{dont}{diff}[0]=sub($$$$){
	my($a,$b,$c,$d)=@_;

	return 0;
};
$pm{handle}{skipped}[0]=sub($$$$){
	my($a,$b,$c,$d)=@_;

	return 0;
};
$pm{ignore}{diff}[0]=sub($$$$){
	my($a,$b,$c,$d)=@_;

	return 0;
};
$pm{handle}{diff}[0]=sub($$$$){
	my($a,$b,$c,$d)=@_;

	return 0;
};
$pm{ignore}{common}[0]=sub($$$$){
	my($a,$b,$c,$d)=@_;

	return 0;
};
$pm{handle}{common}[0]=sub($$$$){
	my($a,$b,$c,$d)=@_;

	return 0;
};
$pm{ignore}{only}[0]=sub($$$$){
	my($a,$b,$c,$d)=@_;

	return 0;
};
sub rmdirl2(;@){
	@_=$_ unless $_[0];
	@_=grep{-d} @_ if @_;
	rmdir foreach @_;
	@_=grep{-d} @_ if @_;
	rmdirl2(map {/^(.*)$/;$1} grep{-d} glob(map{$_.'/*'} @_)) if @_;
	@_=grep{-d} @_ if @_;
	rmdir foreach @_;
	@_=grep{-d} @_ if @_;
	return systemp(qw(rmdir --ignore-fail-on-non-empty), @_)if @_;
}
sub rmdirl(;@){
	$_[0]=$_ unless $_[0];
	@_=grep{-d} @_;
	rmdir foreach @_;
	@_=grep{-d} @_;
	return systemp(qw(rmdir --ignore-fail-on-non-empty), @_)if @_;
}
$pm{handle}{only}[0]=sub($$$$){
	my($a,$b,$c,$d)=@_;
	return 0;
};

1;

################ Documentation ################
__END__
