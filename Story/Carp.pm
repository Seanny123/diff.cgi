package Story::Carp;

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
use Carp qw();
use Exporter qw();

our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
$VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)/g;

@ISA	= qw(Exporter Carp);
@EXPORT = qw(
	croak
	carp
);
%EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],
our @EXPORT_common= qw(
	cluck confess croak carp
);
our @EXPORT_cgi = qw(
	carpout fatalsToBrowser warningsToBrowser wrap set_message set_die_handler set_progname ^name= die
);
our @EXPORT_carp = qw(
	longmess shortmess
);
our @EXPORT_FAIL = qw(verbose);
@EXPORT_OK = (@EXPORT_common, @EXPORT_cgi, @EXPORT_carp, @EXPORT_FAIL);
our %EXPORT_common = map {$_,$_} @EXPORT_common;
our %EXPORT_cgi = map {$_,$_} @EXPORT_cgi;
our %EXPORT_carp = map {$_,$_} @EXPORT_carp;

###############
#	      #
# Subroutines #
#	      #
###############

sub export_fail;
sub import;


sub export_fail { shift; $Carp::Verbose = shift if $_[0] eq 'verbose'; @_ }
sub import {
	my $pkg = shift;
	my(%routines);
	my(@name);
	if (@name=grep(/^name=/,@_)){
		my($n) = (split(/=/,$name[0]))[1];
		$CGI::Carp::PROGNAME=$n;
		@_=grep(!/^name=/,@_);
	}

	grep($routines{$_}++,@_);
	$CGI::Carp::WRAP++ if $routines{'fatalsToBrowser'} || $routines{'wrap'};
	$CGI::Carp::WARN++ if $routines{'warningsToBrowser'};

	unless($ENV{GATEWAY_INTERFACE}){
		*warningsToBrowser = *fatalsToBrowser = *wrap = sub{Carp::carp 'Not implemented for gateway' if $_[0]};
		@_=grep {$EXPORT_common{$_}||$EXPORT_carp{$_}} @_;
		Carp->import(@_)
	}elsif($ENV{GATEWAY_INTERFACE}=~/^CGI\/(1\.?[0-9]*)$/){
		require CGI::Carp;
		@_=grep {$EXPORT_common{$_}||$EXPORT_cgi{$_}} @_;
		CGI::Carp->import(@_)
	}else{
		warn "unknown gayeway: ".$ENV{GATEWAY_INTERFACE};
	}

	my($oldlevel) = $Exporter::ExportLevel;
	$Exporter::ExportLevel += 1;
	Exporter::import($pkg,keys %routines);
	$Exporter::ExportLevel = $oldlevel;
}

1;

################ Documentation ################
__END__
