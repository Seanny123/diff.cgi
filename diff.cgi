#!/usr/bin/perl -t

use strict;
use warnings;
#use diagnostics;
use CGI qw(:standard);
use Story::Carp qw(fatalsToBrowser warningsToBrowser);
use open ':encoding(utf8)';
use Story::Config;
use Story::Common;
use Story::Diff;
no warnings qw(Story::Common);

binmode(STDOUT, ':utf8');
binmode(STDIN,  ':utf8');

END{
	warn 'exiting with '.$? if $?;
}

###############
#	      #
# Subroutines #
#	      #
###############

	sub getparams();
	sub dodiff(;$);
	sub doeachdiff($$$);
	sub diffmain();

############
#	   #
# Varables #
#	   #
############

	my  $count=8;
	my  $offset=0;
	our @p=();
	my  $vers;
	my  @list;
	my  $blank=1;
	my  $mode=0;
	our %link;
	our %common;
	our @vimdiff;
	our %vimdiff;
	our %only;
	our %swap;
	our @ident;
	$ENV{PATH}='/bin/:/usr/bin/';
	my  $cfg=new Story::Config;
	our $cgi;
	our $q = $ENV{MOD_PERL} ? CGI->new(shift @_) : CGI->new();

########
#      #
# Body #
#      #
########

	getparams;
	print "Content-Type: text/plain; charset=UTF-8\n\n" if $cfg->debug&2 && $cgi;
	diffmain();
	exit;

###############
#	      #
# Subroutines #
#	      #
###############

sub getparams(){
	unless($ENV{GATEWAY_INTERFACE}){
		while($ARGV[0]){
			if($ARGV[0]	=~s/^-d//){		shift @ARGV if($ARGV[0]eq'');	if($ARGV[0]=~/^([0-9]+)$/){$cfg->debug($1)}else{warn 'bad option value'} shift @ARGV;
			}elsif($ARGV[0]	=~s/^-c//){		shift @ARGV if($ARGV[0]eq'');
				if($ARGV[0]	=~s/^-//){	shift @ARGV if($ARGV[0]eq'');	if($ARGV[0]=~/^([0-9]+)$/){$count-=$1}else{warn 'bad option value'} shift @ARGV;
				}elsif($ARGV[0]	=~s/^\+//){	shift @ARGV if($ARGV[0]eq'');	if($ARGV[0]=~/^([0-9]+)$/){$count+=$1}else{warn 'bad option value'} shift @ARGV;
				}else{								if($ARGV[0]=~/^([0-9]+)$/){$count =$1}else{warn 'bad option value'} shift @ARGV;
				}
			}elsif($ARGV[0]	=~s/^-o//){		shift @ARGV if($ARGV[0]eq'');
				if($ARGV[0]	=~s/^-//){	shift @ARGV if($ARGV[0]eq'');	if($ARGV[0]=~/^([0-9]+)$/){$offset-=$1}else{warn 'bad option value'} shift @ARGV;
				}elsif($ARGV[0]	=~s/^\+//){	shift @ARGV if($ARGV[0]eq'');	if($ARGV[0]=~/^([0-9]+)$/){$offset+=$1}else{warn 'bad option value'} shift @ARGV;
				}else{								if($ARGV[0]=~/^([0-9]+)$/){$offset =$1}else{warn 'bad option value'} shift @ARGV;
				}
			}elsif($ARGV[0]	=~s/^-m//){		shift @ARGV if($ARGV[0]eq'');	if($ARGV[0]=~/^([0-9]+)$/){$mode=$1}else{warn 'bad option value'} shift @ARGV;
			}elsif($ARGV[0]	=~s/^-b//){		shift @ARGV if($ARGV[0]eq'');	if($ARGV[0]=~/^([0-9]+)$/){$blank=$1}else{warn 'bad option value'} shift @ARGV;
			}elsif($ARGV[0]	=~s/^-x//){		shift @ARGV if($ARGV[0]eq'');	if($ARGV[0]=~/^([0-9]+)$/){$cfg->execute($1)}else{warn 'bad option value'} shift @ARGV;
			}elsif($ARGV[0]	=~s/^-p//){		shift @ARGV if($ARGV[0]eq'');	my $temp = shift @ARGV;	$list[$temp]=shift @ARGV;
			}elsif($ARGV[0]	=~m/^-/){		warn 'invalid option ', shift @ARGV;
			}elsif(-d $ARGV[0]){			$ARGV[0]=~/^(.*)$/;	push @p,$1, shift @ARGV;
			}else{					warn 'invalid option ', shift @ARGV;
			}
		}
	}elsif($ENV{GATEWAY_INTERFACE}=~/^CGI\/(1\.?[0-9]*)$/){
		$cgi=$1;
		$cfg->html(1);
		if($q->param()){
			$count	    =$q->param('count'	 )	if($q->param('count'));
			$offset	    =$q->param('offset'	 )	if($q->param('offset'));
			#$cfg->debug($q->param('debug'	 ))	if($q->param('debug'));
			$cfg->xml   ($q->param('xml'	 ))	if($q->param('xml'));
			$cfg->execute($q->param('execute')&28)	if($q->param('execute'));	#1	vimdiff
												#2	gvimdiff
												#4	handle_only
												#8	systemp
												#16	file
												#32	sudo
												#64	handle_ident
			$blank	    =$q->param('blank'   )	if($q->param('blank'));
			$mode	    =$q->param('mode'    )	if($q->param('mode'));
			@list	    =$q->param('list'    )	if($q->param('list'));
			#@p	    =$q->param('p'       )	if($q->param('p'));
		}
	}else{
		die 'unknown gayeway';
	}
}

sub diffmain(){
	$ENV{GATEWAY_INTERFACE}=undef;

	my $ooffset=$offset;
	my $ocount=$count;
	if($offset){
		my $p_cgi=new CGI($q);
		$p_cgi->param(offset=>$ooffset-$ocount);
		$link{previous}=$p_cgi->self_url;
	}
	if(!$count){
		my $n_cgi=new CGI($q);
		$n_cgi->param(offset=>$ooffset+$ocount);
		$link{next}=$n_cgi->self_url;
	}

	if($mode==0){
		print __PACKAGE__,"\n" if $cfg->debug&2;
		@p=super_e(qw(new new2 old r1 r2 r3)) unless(@p);
		@p=super_e(qw(a b)) unless(@p);
		@p=map {s'$'/' unless m'/$';$_} @p;
		@p=super_e('','../') unless(@p);
		@list=('.')unless(@list);
		Header(join(' ','diff.cgi',$mode,@p));
		print join ' ', @p, @list if $cfg->debug&4;
		my $ret=0;
		$ret+=dodiff foreach @list;
		warn $ret if $ret;
		footer;
		exit $ret;
	}else{
		print __PACKAGE__,"\n" if $cfg->debug&2;
		Header(join(' ','diff.cgi',$mode,@p));
		die 'Bad Mode';
	}
}

# rpath, d1, d2, value
sub doeachdiff($$$){
	my $rpath=shift;
	my $a=$_[0];
	my $b=$_[1];

	return unless $count;

	my %d;
	my @diffp=$blank==1?'-b':$blank?'-w':();

	foreach my $i (@_){
		opendir(my $dh, $p[$i].$rpath) || die sprintf "can't opendir %s: %n", $p[$i].$rpath, $!;
		while(my $_=readdir $dh){
			next if '.'eq$_;
			next if '..'eq$_;
			$d{$_}{$i}=(lstat $p[$i].$rpath.'/'.$_)[2] >> 12;
		}
		closedir $dh;
	}
	my $_;
	foreach (sort keys %d){
		return unless $count;
		my @k= sort keys %{$d{$_}};
		my $i=$d{$_};
		die unless @k;
		if(/^\./ && /\.swp$/){
			my $s=$_;my $_;
			$swap{$p[$_].$rpath.'/'.$s}++ foreach @k;
			next;
		}elsif($offset){
			if(@k==1){
				if($k[0]==$a){
					next if ignore_only($p[$a],$p[$b],$rpath,$_);
					$offset--;
					next;
				}else{
					next if ignore_only($p[$b],$p[$a],$rpath,$_);
					$offset--;
					next;
				}
			}elsif(@k==2){
				if($i->{$k[0]}!=$i->{$k[1]}){
					if($i->{$k[0]}==10){
						if($i->{$k[1]}==4){
							$i->{$k[0]}=4;
							redo;
						}elsif($i->{$k[1]}==8){
							$i->{$k[0]}=8;
							redo;
						}else{
							print map {sprintf "%04d\n",$i->{$_}} @k;
							print "$_\n@k\n@[%d]\n";
							die;
						}
					}elsif($i->{$k[0]}==8){
						if($i->{$k[1]}==10){
							$i->{$k[1]}=8;
							redo;
						}else{
							print map {sprintf "%04d\n",$i->{$_}} @k;
							print "$_\n@k\n@[%d]\n";
							die;
						}
					}elsif($i->{$k[0]}==4){
						if($i->{$k[1]}==10){
							$i->{$k[1]}=4;
							redo;
						}else{
							print map {sprintf "%04d\n",$i->{$_}} @k;
							print "$_\n@k\n@[%d]\n";
							die;
						}
					}else{
						print map {sprintf "%04d\n",$i->{$_}} @k;
						print "$_\n@k\n@[%d]\n";
						die;
					}
				}elsif($i->{$k[0]}==10){# link
					if((readlink $p[$a].$rpath.'/'.$_)eq(readlink $p[$b].$rpath.'/'.$_)){
						next unless $cfg->execute&64;
						next if ignore_common($p[$a],$p[$b],$rpath,$_);
						$offset--;
						next;
					}else{
						next if ignore_diff($p[$a],$p[$b],$rpath,$_);
						$offset--;
						next;
					};
				}elsif($i->{$k[0]}==8){# file
					if(dont_diff($p[$a],$p[$b],$rpath,$_)){
						$offset--;
						next;
					}else{
						system(qw(/usr/local/bin/diff-q), @diffp, ($p[$a].$rpath.'/'.$_), ($p[$b].$rpath.'/'.$_));
						die "failed to execute: $!" if ($? == -1);
						die sprintf 'child died with signal %d, %s coredump', ($? & 127),  ($? & 128) ? 'with' : 'without' if($? & 127);
						die sprintf 'child exited with value %d', $? >> 8 if ($? >> 8) > 1;
						if($?){
							next if ignore_diff($p[$a],$p[$b],$rpath,$_);
							$offset--;
							$vimdiff{$rpath.'/'.$_}++;
							next;
						}else{
							next unless $cfg->execute&64;
							next if ignore_common($p[$a],$p[$b],$rpath,$_);
							$offset--;
							next;
						}
					}
				}elsif($i->{$k[0]}==6){#block
					next unless $cfg->execute&128;
					print "$_\n@k\n$rpath\n";
					die;
				}elsif($i->{$k[0]}==4){#dir
					next if ignore_common($p[$a],$p[$b],$rpath,$_);
					$common{$rpath.'/'.$_}++;
					next;
				}elsif($i->{$k[0]}==2){#char
					next unless $cfg->execute&128;
					print "$_\n@k\n$rpath\n";
					die;
				}elsif($i->{$k[0]}==1){#pipe
					next unless $cfg->execute&128;
					print "$_\n@k\n$rpath\n";
					die;
				}else{
					print map {sprintf "%04d\n",$i->{$_}} @k;
					print "$_\n@k\n@[%d]\n";
					die;
				}
			}else{
				warn scalar @k;
			}
			print "$_\n@k\n@[%d]\n";
			die;
		}elsif($count){
			if(@k==1){
				if($k[0]==$a){
					next if ignore_only($p[$a],$p[$b],$rpath,$_);
					$count--;
					$only{"$rpath/$_"}{$p[$a]}{$p[$b]}{$rpath}{$_}++;
					handle_only($p[$a],$p[$b],$rpath,$_) if $cfg->execute&4;
					next;
				}else{
					next if ignore_only($p[$b],$p[$a],$rpath,$_);
					$count--;
					$only{"$rpath/$_"}{$p[$b]}{$p[$a]}{$rpath}{$_}++;
					handle_only($p[$b],$p[$a],$rpath,$_) if $cfg->execute&4;
					next;
				}
			}elsif(@k==2){
				if($i->{$k[0]}!=$i->{$k[1]}){
					if($i->{$k[0]}==10){
						if($i->{$k[1]}==4){
							$i->{$k[0]}=4;
							redo;
						}elsif($i->{$k[1]}==8){
							$i->{$k[0]}=8;
							redo;
						}else{
							print "$_\n@k\n@[%d]\n";
							print map {sprintf "%04d %s\n",$i->{$_}, $_} @k;
							print "$_\n@k\n@[%d]\n";
							die 'incompatable file types';
						}
					}elsif($i->{$k[0]}==4){
						if($i->{$k[1]}==10){
							$i->{$k[1]}=4;
							redo;
						}else{
							print "$_\n@k\n@[%d]\n";
							print map {sprintf "%04d %s\n",$i->{$_}, $_} @k;
							print "$_\n@k\n@[%d]\n";
							die 'incompatable file types';
						}
					}elsif($i->{$k[0]}==8){
						if($i->{$k[1]}==10){
							$i->{$k[1]}=8;
							redo;
						}else{
							print "$_\n@k\n@[%d]\n";
							print map {sprintf "%04d %s\n",$i->{$_}, $_} @k;
							print "$_\n@k\n@[%d]\n";
							die 'incompatable file types';
						}
					}else{
						print "$_\n@k\n@[%d]\n";
						print map {sprintf "%04d %s\n",$i->{$_},$_} @k;
						print "$_\n@k\n@[%d]\n";
						die 'incompatable file types';
					}
				}elsif($i->{$k[0]}==10){# link
					if((readlink $p[$a].$rpath.'/'.$_)eq(readlink $p[$b].$rpath.'/'.$_)){
						next unless $cfg->execute&64;
						next if ignore_common($p[$a],$p[$b],$rpath,$_);
						$count--;
						handle_common($p[$a],$p[$b],$rpath,$_);
						next;
					}else{
						next if ignore_diff($p[$a],$p[$b],$rpath,$_);
						$count--;
						$vimdiff{$rpath.'/'.$_}++;
						handle_diff($p[$a],$p[$b],$rpath,$_);
						next;
					};
				}elsif($i->{$k[0]}==8){# file
					if(dont_diff($p[$a],$p[$b],$rpath,$_)){
						$count--;
						handle_skipped($p[$a],$p[$b],$rpath,$_);
						next;
					}else{
						use Scalar::Util qw(tainted);
						warn 'diffp tainted' if tainted(@diffp);
						warn 'p tainted' if tainted(@p);
						warn 'p[a] tainted' if tainted($p[$a]);
						warn 'p[b] tainted: '.$p[$b] if tainted($p[$b]);
						warn 'p[a]: '.$p[$a] if tainted($p[$b]);
						warn 'rpath tainted' if tainted($rpath);
						warn 'a tainted' if tainted($a);
						warn 'b tainted' if tainted($b);
						warn 'this tainted' if tainted($_);
						my $ret=system(qw(/usr/local/bin/diff-q), @diffp, ($p[$a].$rpath.'/'.$_), ($p[$b].$rpath.'/'.$_)); ### taint
						die "failed to execute: $!" if ($ret == -1);
						die sprintf 'child died with signal %d, %s coredump', ($? & 127),  ($? & 128) ? 'with' : 'without' if ($ret & 127);
						die sprintf 'child exited with value %d', $? >> 8 if ($ret >> 8) > 2;;
						next if ($ret >> 8) > 1;;
						if($ret){
							next if ignore_diff($p[$a],$p[$b],$rpath,$_);
							$count--;
							$vimdiff{$rpath.'/'.$_}++;
							handle_diff($p[$a],$p[$b],$rpath,$_);
							next;
						}else{
							next unless $cfg->execute&64;
							next if ignore_common($p[$a],$p[$b],$rpath,$_);
							$count--;
							handle_common($p[$a],$p[$b],$rpath,$_);
							next;
						}
					}
				}elsif($i->{$k[0]}==6){#block
					next unless $cfg->execute&128;
					print "$_\n@k\n$rpath\n";
					die;
				}elsif($i->{$k[0]}==4){#dir
					next if ignore_common($p[$a],$p[$b],$rpath,$_);
					$common{$rpath.'/'.$_}++;
					next;
				}elsif($i->{$k[0]}==2){#char
					next unless $cfg->execute&128;
					print "$_\n@k\n$rpath\n";
					die;
				}elsif($i->{$k[0]}==1){#pipe
					next unless $cfg->execute&128;
					print "$_\n@k\n$rpath\n";
					die;
				}else{
					print "handle_common($p[$a],$p[$b],$rpath,$_)\n";
					print map {sprintf "%04d\n",$i->{$_}} @k;
					print "$_\n@k\n$rpath\n";
					die;
				}
			}else{
				warn scalar @k;
				print "$_\n@k\n@[%d]\n";
				die;
			}
		}else{
			print "$_\n@k\n@[%d]\n";
			die;
		}
	}
}
sub dodiff(;$){
	die 'insufficient paths' unless @p;
	if(@p==1){
		my $_=$p[0];
		push @p, super_e(qw(old/security.debian.org/ /home/debian/security.debian.org/)) if 'security.debian.org/'eq$_;
		push @p, super_e(qw(old/ftp.us.debian.org/debian/ /home/debian/master/)) if 'ftp.us.debian.org/debian/'eq$_;
	}
	die 'insufficient paths' unless @p>1;
	my $rpath=@_?$_[0]:$_;
	local $_;
	local @p=grep { -d $_.$rpath } @p;
	return 0 unless (@p>1);
	my $i; my $j;
	for($j=1;$j<@p;$j++){
		for($i=0;$i<$j;$i++){
			doeachdiff($rpath,$i,$j);
		}
	}
	my @only=grep {!$vimdiff{$_}} keys %only;
	@only = grep {-e} (
		map {
			my $i=$p[$_];
			$i?map {$i.$_} @only:()
		} (0 .. scalar(@p))
	);
	@ident=grep {$_} @ident;
	if(@ident){
		print 'Ident:',($cfg->html?'<br/>':''),"\n";
		print "<pre>\n" if $cfg->html;
		print @ident;
		print "</pre>\n" if $cfg->html;
	}
	if(@only){
		print 'Only:',($cfg->html?'<br/>':''),"\n" if($cfg->debug);
		print "<pre>\n" if $cfg->html;
		system qw(ls -lda --color=auto --), @only if($cfg->debug);
		print "</pre>\n" if $cfg->html;
	}
	foreach my $this (@vimdiff){
		if($cfg->html){
			### need vimdiff  equivlent for x1, x2
			### fix link
			print(qq(<a href="">compare),map {' '.$_} grep {-f} map {$_.$this} (@p));
			print('</a><br/>',"\n");
			### does x32 apply to cgi at all?
			if($cfg->execute&16){
				my $fh;
				print(qq(<table border=1><tr>\n));
				open($fh, '-|', qw(file -F </td><td>), grep {-f} map {$_.$this} (@p));
				while(<$fh>){
					s!^!<tr><td>!;
					s~$~</td></tr>~;
					print;
				}
				print(qq(</tr></table>\n));
			}
		}else{
			system qw(file), grep {-f} map {$_.$this} (@p) if $cfg->execute&16;
			if($this =~ /\.(doc|lit|rb|rtf|epub|zip)$/){
				print "Blocked by type: $1.\n";
				print join ' ',map {"'$_'"} grep {-f} map {$_.$this} (@p);
				print "\n";
				next;
			}
			if($this =~ /\.(gif|jpg|jpeg)$/){
				my @tmp=grep {-f} map {$_.$this} (@p);
				print join ' ',map {"'$_'"} @tmp;
				print "\n";
				systemp qw(xli), @tmp;
				next;
			}
			if($this =~ /\.ico$/){
				print "Blocked by type: icon.\n";
				next;
			}
			my @swap = grep {$swap{$_.$this}} @p;
			if(@swap){
				print 'Blocked by swap file:', map {' '.$_.$this} @swap;
				print "\n";
				next;
			}
			my @vdiff=(grep {-f} map {$_.$this} (@p));
			vdiff(@vdiff) if @vdiff > 1;
		}
	}
	my $ret=0;
	if($count){
		foreach my $z (sort keys %common){
			local %common=();
			local @vimdiff=();
			local %vimdiff=();
			local %only=();
			local %swap=();
			$ret+=dodiff($z);
		}
	}
	warn $ret if $ret;# if($cfg->debug);
	return 1 if $ret;
	return 0;
}

1;

################ Documentation ################
__END__
