#!/usr/bin/perl

package SQL::Builder::Union;

use warnings;
use strict;

use SQL::Builder::Junction;

use base qw(SQL::Builder::Junction);

sub junction	{
	return "UNION"
}

1;
