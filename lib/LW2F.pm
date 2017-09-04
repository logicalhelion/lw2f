package LW2F;

use 5.010;
use strict;
use warnings;


our $VERSION = '0.02_3570';


# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

LW2F - LightWeight FastCGI Framework (prototype)

=head1 SYNOPSIS

  use LW2F;
  blah blah blah

=head1 DESCRIPTION

LW2F is a research project designed to be a lightweight framework for FastCGI
applications.

An LW2F application would consist of at least 2 parts, an instance script run
by the application server, and a main application class that subclasses the
LW2F::App class.

An application's instance script can be run by a web server that supports
FastCGI, such as the Apache HTTP Server with the mod_fcgid module, or the
included lw2fd command, which will bind your application processes to a TCP
port, which can receive FastCGI requests from web servers such as nginx and
Apache with the mod_proxy_fcgi module.

=head1 AUTHOR

Logical Helion, LLC, E<lt>lhelion at cpan dot orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Logical Helion, LLC.

This library is free software; you can redistribute it and/or 
modify it under the terms of the Artistic License 2.0.  See the 
included LICENSE file for details.

This software comes with no warranty of any kind.

=cut
