package LW2FX::JSONOutput;

use 5.010;
use strict;
use warnings;
use parent qw(Exporter);
use JSON::Tiny 'encode_json';
$JSON::Tiny::TRUE  = 1;
$JSON::Tiny::FALSE = 0;

our $VERSION = '0.00_00000';

our @EXPORT = qw(
    _postrun_lw2f_plugin_jsonoutput
);


#[] this is out of the CGI::Application POD...hope it works.
sub import {
    my $caller = scalar(caller);    
    $caller->add_callback('postrun', '_postrun_lw2f_plugin_jsonoutput');
    goto &Exporter::import;
}


sub _postrun_lw2f_plugin_jsonoutput {
    my $self = shift;
    my $response = shift;
    print STDERR 'REF=',ref($response);    #[]
    
    # if the response data points to a scalar,
    # then the current run mode is doesn't need JSON
    # conversion; just pass on thru
    return 1 if ref($response) eq 'SCALAR';
    print STDERR ' RREF=',ref($$response);    #[]
    
    my $json = encode_json($$response);
    
    $self->header_add(-type => 'application/json; charset=UTF-8');
    $$response = $json;
}


1;
__END__

=head1 NAME

LW2FX::JSONOutput - 

=head1 SYNOPSIS

 # in your application class
 use strict;
 use warnings;
 use parent 'LW2F::App';
 use LW2F::Plugin::JSONOutput;  # this adds a postrun callback to your app
 
 # an example run mode
 sub my_run_mode {
    my $self = shift;
    ... do backend things for your web app ...
    
    # Create a Perl data structure of your response
    my $response = {
        data1 => "value1",
        data2 => "value2"
    };
    
    # Return the response data structure
    # The postrun callback will automatically convert your Perl
    # structure to a JSON object and set the response headers to
    # indicate the appropriate MIME type.
    return $response;
 }

=head1 DESCRIPTION


Blah blah blah. #[]



=head1 AUTHOR

Logical Helion, LLC, E<lt>lhelion at cpan dot orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Logical Helion, LLC.

This library is free software; you can redistribute it and/or 
modify it under the terms of the Artistic License 2.0.  See the 
included LICENSE file for details.

This software comes with no warranty of any kind.

=cut
