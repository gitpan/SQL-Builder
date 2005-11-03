#!/usr/bin/perl

package SQL::Builder::AnyObject;

use warnings;
use strict;

use Carp qw(confess);
use Data::Dumper;


sub new	{
	my $class = shift;
		$class = ref($class) || $class;
	my $self = bless {}, $class;

	$self->init;
	
	if(@_)	{
		$self->set(@_);
	}

	return $self;
}



# internal mechanism for object property storage

sub _set	{
	my $self = shift;
	my $key = shift;
	
	if(@_)	{
		$$self{$key} = $_[0];
		#$_[0]->parent($self) if $self->is_sb($_[0]) && $_[0]->id ne $self->id;
		return $self
	}

	return $$self{$key}
}


# internal mechanism for object property unstorage

sub _unset	{
	my ($self, $key) = @_;

	return delete $$self{$key}
}


# internal mechanism to get/set attributes. called with a single attribue, a value is returned
# called with more than one, values are set

sub options	{
	my $self = shift;

	if(@_ >= 2)	{

		confess "Invalid argument pattern, expecting even list"
			if @_ % 2;
		
		my %opts = @_;

		foreach my $opt (keys %opts)	{
			$$self{opts}{$opt} = $opts{$opt}
		}

		return $self;
	}
	elsif(@_)	{
		return $$self{opts}{$_[0]}
	}
	else	{
		return $$self{opts}
	}
}

# handle arguments to the constructor

sub _quick_arg_handler	{
	my $self = shift;

	my ($args, $options, $control) = @_;
		
		## DO SOME ARG VALIDATION

		if(ref $args ne 'HASH')	{

			# expect a hashref or even list
			
			if(@_ % 2)	{
				confess "Invalid argument pattern, expecting even list or hash ref:\n"
						. Dumper(\@_)
			}
			elsif(@_)	{

				$args    = {@_};
				$options = {};
				$control = {};
			}
		}
		
		$args    = {} unless $args;
		$options = {} unless $options;
		$control = {} unless $control;
		
		for($args, $options, $control)	{
			confess "Invalid argument -- not a hash ref"
				unless ref $_ eq 'HASH'
		}

		## SET SOME DEFAULTS

		$$control{catch_errors} = 1 unless defined $$control{catch_errors};


	## PROCESS ARGUMENT LIST

	foreach my $method_list (keys %$args)	{

		my @method_list = split /->|-|~/, $method_list;

		my $args = ref $args->{$method_list} eq 'ARRAY'
		               ? $args->{$method_list}
		               : [$args->{$method_list}];

		my $ref;

		# resolve "method-bar-foo" as "method->bar->foo"

		while(@method_list)	{

			my $pass_args;

			if(@method_list == 1)	{
				$pass_args = $args;
			}	
			else	{
				$pass_args = [];
			}

			my $func = shift @method_list;
			
			# the first method should be called on $self
			$ref = $self unless defined $ref;

			$ref = $self->_quick_arg_method_caller($ref, $func, $pass_args, $$control{catch_errors})
		}
	}



	## PROCESS OPTIONS

	$self->options(%$options) if keys %$options;
}


# call a method dynamically

sub _quick_arg_method_caller	{
	my ($self, $base, $method, $args, $catch) = @_;

		confess "Expected method argument not passed or invalid"
			unless defined($method) && length($method);

		confess "Expected base/reference argument not passed or invalid"
			unless ref $base;

		confess "Args should be an array ref"
			unless ref $args eq 'ARRAY';

		confess "Base/reference has no such method ($method)\n" . Dumper($base)
			unless UNIVERSAL::can($base, $method);
	
	my $retval;
	
	if($catch)	{

		eval	{
			$retval = $base->$method(@$args)
		};

		confess "Method $method threw an error: $@"
			if $@;
	}
	else	{

		$retval = $base->$method(@$args)
	}

	return $retval
}


# used for child classes only
# this is called with arguments passed to the constructor

sub set	{
	return shift->_quick_arg_handler(@_)
}


# used for child classes only
# this should do any initial setup necessary
# no params required

sub init	{ }

1;
