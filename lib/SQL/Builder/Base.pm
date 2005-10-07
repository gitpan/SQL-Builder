#!/usr/bin/perl

package SQL::Builder::Base;

use warnings;
use strict;

use Carp qw(confess);
#use Scalar::Util qw(blessed weaken);
use Data::Dumper;
use Clone;

#use overload '""' => \&stringify;
#sub stringify	{ return shift->sql }

use SQL::Builder::Iterator;

our %ID;

# the constructor
# pass set() arguments

sub new	{
	my $class = shift;
		$class = ref($class) || $class;
	my $self = bless {}, $class;

	$self->id(1 + keys %ID);

	$self->init;
	
	if(@_)	{
		$self->set(@_);
	}

	return $self;
}

sub id	{
	my $self = shift;
	
	if(@_)	{

		$ID{$_[0]} = $self;
	}

	return $self->_set('ID', @_)
}

# used for child classes only
# this should do any initial setup necessary
# no params required

sub init	{ }

# used for child classes only
# this is called with arguments passed to the constructor

sub set	{
	confess "Not implemented"
}

# get the SQL representation of an object
# called with an option hashref of context

sub sql	{
	confess "Not implemented"
}

# if an object can sql() the method is called and its result is returned
# otherwise, the var will be returned
sub cansql	{
	#return UNIVERSAL::can($_[1], 'sql') ? $_[1]->sql : $_[1]
	if(UNIVERSAL::can($_[1], 'sql'))	{
		return $_[1]->sql
	}
	else	{
		return $_[1]
	}
}

# check to see if something is a SQL::Builder::Base
sub is_sb	{
	my $self = shift;
	return UNIVERSAL::isa(shift, __PACKAGE__)
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

# a method for child classes to optionally implement
# allows the user to use perl data structures to instantiate objects

sub quick	{
	confess "quick() not implemented for object"
}

############ TREE NAVIGATION METHODS

# get/set the parent/current owner of the element if applicable

sub parent	{
	my $self = shift;
	
	confess "Cannot set parent to self"
		if $self->is_sb($_[0]) && $_[0]->id eq $self->id;
	
	return $self->_set('_parent', @_)
}

# return an iterator for all of the 
sub parents	{
	my $self = shift;
	my $obj = $self;
	
	# return unless we have at least one parent
	#return () unless defined $self->parent;

	return SQL::Builder::Iterator->new(sub{
		my $it = shift;
		
		# return an empty list if we're exhausted
		return () if $it->exhausted;
		
		$obj = $obj->parent;

		if(defined $obj)	{
			$it->set_current($obj);
			$it->hist_push($obj);
			return 1
		}
		else	{
			$it->set_exhausted(1);
			return ()
		}
	});
}

# make an iterator given a aref
sub _make_children_iterator	{
	my ($self, $list) = @_;
	my $i = 0;

	#return () unless @$list;

	return SQL::Builder::Iterator->new(sub	{
		my $it = shift;
		
		# exit if we're exhausted
		return () if $it->exhausted;
		
		# or if there aren't any elements or we've gone too far
		return () unless @$list && $i < @$list;
		
		# get the next item, tell the $it where we are
		$it->set_current($$list[$i]);
		
		# keep track of where we've been
		$it->hist_push($it->current);
		
		# don't iterate infinitely
		$i++;

		return 1;
	});
}

# get an iterator for the elements. returns empty list if none.
# should return a child iterator or list depending on context
sub children	{
	# empty
	return
}

# determine the class type of an object
sub type	{
	my ($self, $check) = @_;

	return UNIVERSAL::isa($self, $check) unless defined $check;

	return ref $self
}

# is this object exactly a type
sub is	{
	my ($self, $check) = @_;

	return defined($check) && ref($self) eq $check
}

BEGIN {
	my %actions = (
		# we may want to inline this in _has for
		# better performance
		code => sub	{
			# item, check, self
			return $_[1]->($_[0], $_[2])
		},
		eq => sub	{
			return $_[0] eq $_[1]
		},
		is => sub	{
			return ref $_[0] eq $_[1]
		},
		isa => sub	{
			return UNIVERSAL::isa($_[0], $_[1])
		}
	);

	sub _has	{
		my ($self, $list, $type, $check) = @_;

		confess "Invalid type $type" unless exists $actions{$type};

		foreach my $item (@$list)	{
			my $ret = $actions{$type}->($item, $check, $self);

			return $ret if $ret;
		}
	}
}

# a child method
# should normally implement _has
# throws an exception
# sub has{}

sub _find_is_interesting	{
	my ($self, $node, $args) = @_;

	if($$args{_CODE})	{

		if(my $ret = $$args{_CODE}->($node, $self))	{
			return $ret
		}
	}
	else	{

		my $failed = 0;

		foreach my $attr (keys %$args)	{

			# skip special commands
			next if $attr =~ /^_[A-Z_]+/;

			my $check = $$args{$attr};
			
			if($attr eq '_class')	{
				$failed = 1
					unless ref $attr eq $check
			}
			elsif($attr eq '_isa')	{
				$failed = 1
					unless UNIVERSAL::isa($node, $check)
			}
			elsif(!UNIVERSAL::can($node, $attr))	{
				$failed = 1
			}
			elsif(!defined $check)	{
				$failed=1
					if defined $node->$attr
			}
			elsif(ref $check eq 'CODE')	{
				$failed=1
					unless $check->($node, $attr, $node);
			}
			elsif(ref $check eq 'ARRAY')	{
				$failed=1
					unless $node->$attr(@$check)
			}
			else	{
				$failed=1
					unless $node->$attr eq $check
			}

			last if $failed
		}

		return 1 unless $failed;
	}

	return
}

sub look_down	{
	my ($self, %args) = @_;

	if($args{_BREADTH})	{
		return $self->look_down_breadth(%args);
	}

	my @agenda = ($self);
	my @wanted;
	my $RETURN = [];

	my $walk = sub	{
		my $main_it = shift;

		AGENDA:
		while(@agenda)	{
			my $node = pop @agenda;

			if($RETURN eq $node)	{
				$main_it->set_current(pop @wanted);
				$main_it->hist_push($main_it->current);
				return 1;
			}
			
			my $is_wanted = $self->_find_is_interesting($node, \%args);
			
			# determine if we want this node

			if($is_wanted)	{
				push @wanted, $node;

				if(!$args{_TOP_DOWN})	{
					push @agenda, $RETURN;
				}
			}
			
			# get the nodes children
			if($self->is_sb($node))	{
				my $children_it = $node->children;

				if($children_it)	{
					my @kids;

					while($children_it->pull)	{
						push @kids, $children_it->current
					}
					
					# assert
					confess "Number of returned children should be at least 1"
						unless @kids;
					
					# keep walking the tree
					# since we're popping the agenda, reverse this to keep order
					
					push @agenda, reverse @kids;

					if($args{_TOP_DOWN} && $is_wanted)	{
						push @agenda, $RETURN
					}
				}
			}
		}
		
		$main_it->set_exhausted(1);

		return ()
	};
	
	return SQL::Builder::Iterator->new($walk);
}

sub look_down_breadth	{
	my ($self, %args) = @_;

	my @agenda = ([$self]);
	my $RETURN = [];

	return SQL::Builder::Iterator->new(sub	{
		my $it = shift;

		while(@agenda)	{
			my $item = pop @agenda;

			if(ref $item eq 'ARRAY')	{
				my @wanted;
				my @kids;# children of the current level, in order

				foreach my $node (@$item)	{
					if($self->_find_is_interesting($node, \%args))	{
						push @wanted, $node
					}

					next unless $self->is_sb($node);

					my $children = $node->children;

					if($children)	{

						while($children->pull)	{
							push @kids, $children->current
						}
					}
				}

				push @agenda, [@kids] if @kids;

				# add the iteresting items to return
				push @agenda, reverse @wanted;
			}
			else	{
				$it->set_current($item);
				$it->hist_push($item);
				return 1;
			}
		}

		$it->set_exhausted(1);
		return ()
	})
}

sub look_up	{
	my ($self, %args) = @_;

	my $parents = $self->parents;

	return () unless $parents;

	return SQL::Builder::Iterator->new(sub	{
		my $it = shift;

		while($parents->pull)	{
			my $parent = $parents->current;

			if($parent && $self->_find_is_interesting($parent, \%args))	{
				$it->set_current($parent);
				$it->hist_push($parent);
				return 1;
			}
		}

		$it->set_exhausted(1);

		return ()
	})
}

sub descend_on	{
	my ($self, %args) = @_;
	
	my @agenda;
	my $RETURN = [];
	my $parents = $self->parents;

	return () unless $parents;

	while($parents->pull)	{
		push @agenda, $parents->current
	}

	return SQL::Builder::Iterator->new(sub	{
		my $it = shift;

		while(@agenda)	{
			my $node = pop @agenda;

			if($self->_find_is_interesting($node, \%args))	{
				$it->set_current($node);
				$it->hist_push($node);

				return 1;
			}
		}

		$it->set_exhausted(1);
		return ();
	})
}

sub dbh	{
	return shift->_set('dbh', @_)
}

sub run	{
	my $self = shift;

	confess "No dbh set"
		unless $self->dbh;
	
	my $sql = $self->sql;

	my $sth = $self->dbh->prepare($sql);

	$sth->execute()
		or confess "Unable to run query: $DBI::errstr: ($sql)";

	return $sth
}
1;
