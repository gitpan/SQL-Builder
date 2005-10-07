#!/usr/bin/perl

package SQL::Builder::Intersect;

use warnings;
use strict;

use SQL::Builder::Junction;

use base qw(SQL::Builder::Junction);

sub junction	{
	return "INTERSECT"
}

1;
