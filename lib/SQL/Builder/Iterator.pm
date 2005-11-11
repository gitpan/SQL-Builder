#!/usr/bin/perl

package SQL::Builder::Iterator;

use warnings;
use strict;

use Carp qw(confess);

sub new	{
	my $class = shift;
		$class = ref($class) || $class;

	return bless {
		exhausted => 0, pull => shift,
		history => [], current => undef
	}, $class
}

### use this to iterate over results

sub pull	{
	my ($self) = @_;
	
	return () if $self->exhausted;
	
	if($$self{pull}->($self))	{
		return $self->current;
	}
	
	return ()
}


### exhausted?

sub set_exhausted	{
	my $self = shift;
	$$self{exhausted} = shift;
}

sub exhausted	{
	return shift->{exhausted}
}

sub not_exhausted	{
	return !shift->{exhausted}
}

### Current value of the iterator

sub set_current	{
	my $self = shift;
	$$self{current} = shift;
}

sub current	{
	return shift->{current}
}

### history functions

# completely set the history functions
sub hist_set	{
	shift->{history} = shift
}

# add an item to the history
sub hist_push	{
	push @{shift->{history}}, shift
}

# get a particular item from the history
sub hist_get	{
	return shift->{history}[shift]
}

# return a list of history items
sub hist_list	{
	return @{ shift->{history} }
}


### Navigation functions

sub peek_ahead	{
	my ($self, $count) = @_;
		confess "Expecting positive count" unless $count > 0;

	return () if $self->exhausted;

	my $i = 0;
	my ($current, @visited);
	
	{
		local $$self{history} = [];
		local $$self{exhausted} = 0;
		local $$self{current};
		
		while(($current) = $self->pull)	{
			$i++;

			if($i == $count || $self->exhausted)	{
				last
			}
			else	{
				push @visited, $current
			}
		}
	}
	
	
	return wantarray ? ($current, \@visited) : $current
}

sub peek_back	{
	my ($self, $count) = @_;
		confess "Expecting positive count" unless $count > 0;

	return () unless @{$$self{history}};

	my $i = 1;
	my ($current, @visited);
	
	while(@{$$self{history}})	{
		$current = $$self{history}->[-$i];
		last if $i == $count;
		$i++;
	}
	
	
	return wantarray ? ($current, \@visited) : $current
}

1;

=head1 NAME

SQL::Builder::Iterator - Iterate over results produced by search functions in Base.pm

=head1 SYNOPSIS

	my $iterator = $any_sql_builder_object->look_down;

	while($iterator->pull)	{
		my $current_object = $iterator->current;

		# ...
	}

=head1 DESCRIPTION

This class is supposed to make it relatively easy to write iterators. Currrently
it allows you to track history, fast-forward, and rewind, but none if it has
been tested very well. This class is likely to change so I'll leave any
documentation to the source of SQL::Builder::Base(3) which implements it. Once
I've determined it does the right things, I'll properly document it.

=head1 METHODS

=head2 pull()

This method returns true when the iterator could be moved forward. It sets the
value of current(). When there is nothing left in the list, pull() returns false

=head1 current()

After pull() has been called and the iterator has been moved forward, this
method is set and returns the value found.

=head1 SEE ALSO

SQL::Builder::Base(3)
