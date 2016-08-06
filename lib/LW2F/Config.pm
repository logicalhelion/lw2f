package LW2F::Config;

use 5.010;
use strict;
use warnings;
use File::Spec;
use FindBin;

use JSON::Tiny qw(decode_json);
$JSON::Tiny::TRUE  = 1;
$JSON::Tiny::FALSE = 0;

our $VERSION = '0.01_3161';


=head1 DESCRIPTION

=cut

use Class::Tiny qw(
    app_config
    config
    server_config
    app_conf_file
    server_conf_file
), {
   server_conf_file => sub { $ENV{SERVER_CONF_FILE} ? $ENV{SERVER_CONF_FILE} : undef },
};

sub BUILD {
    my ($self, $params) = @_;
    
    if ( defined $params->{app_conf_file} ) {
        $self->app_conf_file( $params->{app_conf_file} );
    }
    
    if (keys %$params) {
        $self->parse_config();
    }
    
}

=head1 METHODS

=head2 parse_config()

=cut

sub parse_config {
    my $self = shift;
    my %params = @_;
 
    foreach my $var (sort grep { /^LW2F/ } keys %ENV) {
        say "CONFIG: ", $var, " = ", $ENV{$var};
    }
 
    
    # die if we don't have the app conf file
    if ( !($self->app_conf_file) && !(-f $self->app_conf_file) ) {
        die("App conf file not set or does not exist.");
    }

    my $acf;
    {
        local $/ = undef; 
        open(my $acfh, '<', $self->app_conf_file) or die($!);
        $acf = <$acfh>;
        close $acfh;
    }
    say $self->app_conf_file;
    say "JSON: $acf";

    
    #[] handle errors better here
    #[] BUT we really should be throwing an exception here
    # if the config isn't valid    
    my $ac = decode_json($acf);
    
    $self->app_config($ac);
    my $config = $self->fixup_config($ac, \%params);
    $self->config($config);
    $config;
}


=head2 fixup_config()

=cut

sub fixup_config {
    my $self = shift;
    my $ac = shift;
    my $params = shift;
    my %app_conf;
    
    # copy app conf values over
    foreach my $key (keys %$ac) {
        $app_conf{$key} = $ac->{$key};
    }

    # copy over run_modes
    if ( defined $app_conf{run_modes} && ref($app_conf{run_modes}) eq 'ARRAY') {
        my @run_modes = map { $_ } @{ $app_conf{run_modes} };
        $app_conf{run_modes} = \@run_modes;
    }
    

    #[] handle baseurls & basedirs
    # this is important for template operation
    # and for app locations to be passed into templates
    # also, if the app has writable files in its directory
    # or needs to write a static file (i.e. a report or some output file)
    # that can be retrieved by the user
    #  app_baseurl handling
    # if app_baseurl was set in the conf file
    # and is an absolute path, everything is fine
    if ( !defined $app_conf{app_basedir} ) {
        # OK, we don't have an app_baseurl at all
        # set it to where the instance script is running from
        $app_conf{app_basedir} = $FindBin::Bin;
    } elsif ( !File::Spec->file_name_is_absolute($app_conf{app_basedir}) ) {
        # OK, we *have* an app_basedir, but it's a relative path
        # attempt to derive the correct app_basedir
        # from the LW2F_APPS_BASEDIR env var
        $app_conf{app_basedir} = File::Spec->catdir( $ENV{LW2F_APPS_BASEDIR}, $app_conf{app_basedir} );
    }
    # now, chdir to the app_basedir
    # throw a fit if it doesn't exist
    if (-d $app_conf{app_basedir}) {
        chdir($app_conf{app_basedir}) || die "ERROR: Could not chdir to app_basedir $app_conf{app_basedir}: $!";
    } else {
        die "ERROR: app_basedir $app_conf{app_basedir} is not a valid directory.  ";
    }
    
    # OK, any other default magic we do with basedirs and baseurls will
    # depend on the directory we are currently running in, so pop the name of
    # the app_baseurl/current directory off
    my @dirs = File::Spec->splitdir( $app_conf{app_basedir} );
    my $app_dir_name = '';
    foreach (reverse @dirs) { if ($_) { $app_dir_name = $_; last; } }   # this means we cannot have an app_basedir named '0'...we are OK with that.
    unless ($app_dir_name) { die("ERROR:  Cannot derive app_basedir name.  Are you trying to run the app from the root directory?"); }
    
    # htdocs_basedir will be similar to app_basedir:
    # if we don't have one, default to where the instance script is running from
    # aka app_basedir, aka current dir at this point.
    # if it is set but is a relative dir, use LW2F_HTDOCS_BASEDIR
    if ( !defined $app_conf{htdocs_basedir} ) {
        # OK, we don't have an app_baseurl at all
        # set it to where the instance script is running from
        $app_conf{htdocs_basedir} = $app_conf{app_basedir};
    } elsif ( !File::Spec->file_name_is_absolute($app_conf{htdocs_basedir}) ) {
        # OK, we *have* an app_basedir, but it's a relative path
        # attempt to derive the correct app_basedir
        # from the LW2F_APPS_BASEDIR env var
        $app_conf{htdocs_basedir} = File::Spec->catdir( $ENV{LW2F_HTDOCS_BASEDIR}, $app_conf{htdocs_basedir} );
    }

    # OK, URLs are tricky because they are really controlled by the web server
    # We will do something similar to the basedirs.
    # If an URL starting with / is set in app.conf,
    # we'll just accept that and that will be available to pass into templates
    # if the URL is relative and LW2F_APPS_BASEURL is set,
    # we will tack the directory we are running from on to the env var
    # If we don't have either, we'll punt & set the baseurl to "/app_dir_name"
    if ( !defined $app_conf{app_baseurl} ) {
        $app_conf{app_baseurl} = '/' . $app_dir_name;
    } elsif ( $app_conf{app_baseurl} !~ /^\// ) {
        # chop trailing slash
        chop $ENV{LW2F_APPS_BASEURL} if $ENV{LW2F_APPS_BASEURL} =~ /\/$/;
        $app_conf{app_baseurl} = $ENV{LW2F_APPS_BASEURL} . '/' . $app_conf{app_baseurl};    
    }

    # Same thing as app_baseurl with htdocs_baseurl
    if ( !defined $app_conf{htdocs_baseurl} ) {
        $app_conf{htdocs_baseurl} = '/' . $app_dir_name;
    } elsif ( $app_conf{htdocs_baseurl} !~ /^\// ) {
        # chop trailing slash
        chop $ENV{LW2F_HTDOCS_BASEURL} if $ENV{LW2F_HTDOCS_BASEURL} =~ /\/$/;
        $app_conf{htdocs_baseurl} = $ENV{LW2F_HTDOCS_BASEURL} . '/' . $app_conf{htdocs_baseurl};    
    }

    # defaults for CGI::Application
    # if these aren't set in app.conf, we will use some defaults
    # this will help the user get started with a minimal conf file

    # if the run_mode path param wasn't set
    # default to 1 (this first part of path_info, after the 1st '/')
    if ( !defined $app_conf{path_mode_param} ) {
        $app_conf{path_mode_param} = 1;
    }
    
    # if there are no run modes,
    # define two called 'index' and 'error'
    if ( !defined $app_conf{run_modes} ) {
        $app_conf{run_modes} = ['index','error'];
    }
    
    # if there is no start_mode defined,
    # default to the first one in the run_modes array
    # if run_modes wasn't originally defined either,
    # this means 'index' will be defined as a run_mode
    # AND the start_mode
    if ( !defined $app_conf{start_mode} ) {
        $app_conf{start_mode} = $app_conf{run_modes}->[0];
    }
    
    # if there is no error_mode, default to 'error'
    # if run_modes wasn't originally defined,
    # this means 'error' will be defined as a run_mode
    # AND the error_mode
    if ( !defined $app_conf{error_mode} ) {
        # first look to see if 'error' is defined as a run mode
        my @erm = grep { /^error$/ } @{ $app_conf{run_modes} };
        if ( !scalar @erm ) {
            # there ISN'T an 'error' run mode, so add it
            push(@{ $app_conf{run_modes} }, 'error' );
        }
        # now set the error_mode to 'error'
        $app_conf{error_mode} = 'error';
    }
    
    # if auto_rest is enabled,
    # auto-generate new run modes for those that don't have
    # an HTTP method assigned to them
    # (they end in '_GET','_POST', etc.)
    # the lw2f_auto_rest_prerun() callback will switch runmodes
    # to these as needed
    if (exists $app_conf{auto_rest} && $app_conf{auto_rest} == 1) {
        my %expanded_rm_h = map { $_ => 1 } map { !/_(GET|POST|PUT|DELETE)$/ ? ($_, $_.'_GET', $_.'_POST', $_.'_PUT',$_.'_DELETE') : $_ } @{ $app_conf{run_modes} };
        my @expanded_rm = sort keys %expanded_rm_h;
        $app_conf{run_modes} = \@expanded_rm;
    }
    
    # if no tmpl_path is defined,
    # assume the templates are in app_basedir/templates
    if ( !defined $app_conf{tmpl_path} ) {
        $app_conf{tmpl_path} = 'templates';
    }
    # turn the specified relative path into an absolute one if it isn't already
    if ( $app_conf{tmpl_path} !~ /^\// ) {
        $app_conf{tmpl_path} = File::Spec->catfile( $app_conf{app_basedir}, $app_conf{tmpl_path} );
    }
    
    # set template options
    # we start with some sane defaults
    # and then if app.conf specified any options,
    # those will override
    my %tmpl_options = (
        die_on_bad_params => 0, 
        loop_context_vars => 1,
        default_escape    => 'html',
        cache             => 1,
    );
    if ( defined $app_conf{tmpl_options} ) {
        foreach (keys %{ $app_conf{tmpl_options} }) {
            $tmpl_options{$_} = $app_conf{tmpl_options}->{$_};
        }
    }
    $app_conf{tmpl_options} = \%tmpl_options;
    
    \%app_conf;    
}


1;
__END__


=head1 AUTHOR

Logical Helion, LLC, E<lt>lhelion at cpan dot orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Logical Helion, LLC.

This library is free software; you can redistribute it and/or 
modify it under the terms of the Artistic License 2.0.  See the 
included LICENSE file for details.

This software comes with no warranty of any kind.

=cut
