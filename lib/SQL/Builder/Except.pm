#!/usr/bin/perl

package SQL::Builder::Except;

use warnings;
use strict;

use SQL::Builder::Junction;

use base qw(SQL::Builder::Junction);

sub junction	{
	return "EXCEPT"
}

1;
