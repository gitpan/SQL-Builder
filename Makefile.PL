#use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SQL::Builder',
    VERSION_FROM      => 'lib/SQL/Builder.pm', # finds $VERSION
    PREREQ_PM         => {
    	    			'Data::Dumper' => 2.121,
			    'Scalar::Util' => 1.14
			    #'Clone' => 0.18,
    			},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SQL/Builder.pm', # retrieve abstract from module
       AUTHOR         => 'sebastian <sili@cpan.org>') : ()),
);
