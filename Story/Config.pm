package Story::Config;

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

our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
$VERSION = sprintf "%d.%03d", q$Revision: 1.3 $ =~ /(\d+)/g;

@ISA	= qw(Exporter);
@EXPORT = qw(
);
%EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],
@EXPORT_OK   = qw();

###############
#	      #
# Subroutines #
#	      #
###############

sub new($;$);
sub html($;$);
sub xml($;$);
sub debug($;$);
sub execute($;$);
sub uri($;$);
sub countdec($);
sub count($;$);
sub offsetdec($;$);
sub offsetinc($;$);
sub offset($;$);
sub recurse($;$);
sub verbose($;$);
sub blank($;$);
sub p($;@);
sub pe($$;$);
sub ppush($$);

###########################
#			  #
# Data Structure Varables #
#			  #
###########################

my %all;

###############
#	      #
# Subroutines #
#	      #
###############

sub new($;$){
	my $class=shift;
	my $context;
	if($_[0]){	$context=shift;
	}else{		($context)=caller
	}
	return $all{$context} if(defined $all{$context});
	my $self={};
	bless($self,$class);
	$all{$context}=$self;
	$self->{debug}=0;
	$self->{execute}=0;
	$self->{count}=10;
	$self->{offset}=0;
	$self->{blank}=1;

	return $self;
}

sub countdec($){
	my $self=shift;
	return $self->{count}--;
}
sub count($;$){
	my $self=shift;
	$self->{count}=shift if(@_);
	return $self->{count};
}

sub offsetdec($;$){
	my $self=shift;
	return $self->{offset}-=shift if(@_);
	return $self->{offset}--;
}
sub offsetinc($;$){
	my $self=shift;
	return $self->{offset}+=shift if(@_);
	return $self->{offset}++;
}
sub offset($;$){
	my $self=shift;
	$self->{offset}=shift if(@_);
	return $self->{offset};
}

sub recurse($;$){
	my $self=shift;
	$self->{recurse}=shift if(@_);
	return $self->{recurse};
}

sub verbose($;$){
	my $self=shift;
	$self->{verbose}=shift if(@_);
	return $self->{verbose};
}

sub blank($;$){
	my $self=shift;
	$self->{blank}=shift if(@_);
	return $self->{blank};
}

sub p($;@){
	my $self=shift;
	$self->{p}=[@_] if(@_);
	return @{$self->{p}};
}
sub pe($$;$){
	my $self=shift;
	my $index=shift;
	$self->{p}[$index]=shift if(@_);
	return $self->{p}[$index];
}
sub ppush($$){
	my $self=shift;
	return push @{$self->{p}}, shift;
}

sub uri($;$){
	my $self=shift;
	$self->{uri}=shift if(@_);
	return $self->{uri};
}

sub html($;$){
	my $self=shift;
	$self->{html}=shift if(@_);
	return $self->{html};
}

sub xml($;$){
	my $self=shift;
	$self->{xml}=shift if(@_);
	return $self->{xml};
}

sub execute($;$){
	my $self=shift;
	$self->{execute}=shift if(@_);
	return $self->{execute};
}

sub debug($;$){
	my $self=shift;
	$self->{debug}=shift if(@_);
	return $self->{debug};
}

1;

################ Documentation ################
__END__
