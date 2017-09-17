use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'LW2F',
    VERSION_FROM      => 'lib/LW2F.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
                            'CGI::Application' => 4.50,
                            'FCGI'             => 0.74,
                            'JSON::Tiny'       => 0.55,
                            'List::Util'       => 1.00
                            
                          }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/LW2F.pm', # retrieve abstract from module
    AUTHOR            => 'Logical Helion, LLC <lhelion at cpan dot org>',
    LICENSE           => 'artistic_2',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
