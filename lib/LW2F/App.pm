package LW2F::App;

use 5.010;
use strict;
use warnings;
use parent 'CGI::Application';

use LW2F::Config;

our $VERSION = '0.02_0170';

our $Config = { };
our $Databases = { };

use Class::Tiny qw(
    config
    server_config
    app_config
    app_name
);

# sub BUILD {}

## CLASS METHODS HERE ##
sub prep {
    my $class = shift;
    my %params = @_;
    
    $Config = LW2F::Config->new(%params);
    
    # install callbacks for init and load_tmpl phase
    $class->add_callback('init', 'lw2f_init');
    $class->add_callback('load_tmpl', 'lw2f_load_tmpl');

    # install callback for prerun phase
    # IF auto_rest was set
    if (exists $Config->config()->{auto_rest} &&
        $Config->config()->{auto_rest} == 1 ) {
        $class->add_callback('prerun', 'lw2f_auto_rest_prerun');
    }

    # if there are databases configured,
    # go ahead and load DBI and connect to them
    if (exists $Config->config()->{databases} ) {
        $class->lw2f_load_dbi();
        $class->lw2f_connect_databases( $Config->config()->{databases} );
    }
    
    $Config;
}


## OBJECT METHODS HERE ##

sub get_config_var {
    my $self = shift;
    my $var_name = shift;
    my $config = $self->config();
    my $chash = $config->config();
#    $chash->{$var_name};
    $self->config()->config()->{$var_name};
}

#[]? better
sub get_config_var_new {
    return $_[0]->config()->config()->{$_[1]};
}

## CGI::APPLICATION METHODS HERE ##

# hooking callback init 
# so we can pull the configuration from the class data
# into the object instance

sub lw2f_init {
    my $self = shift;
    my $params = shift;
    
    if ( defined $params->{conf} ) {
        $self->config( $params->{conf} );
    } elsif ( defined $Config ) {
        $self->config($Config);
    } else {
        print STDERR "No config defined or passed to cgiapp_init()!";
        #[] exception this?
    }
    
}


# overriding setup method
# to set up the app object from the framework configuration

sub setup {
    my $self = shift;
#[] don't need?
#   my $conf = $self->config();
#    my $c = $conf->config();
    
    $self->mode_param( path_info => $self->get_config_var('path_mode_param') );
    $self->run_modes( $self->get_config_var('run_modes') );
    $self->start_mode( $self->get_config_var('start_mode') );
    $self->error_mode( $self->get_config_var('error_mode') );
    $self->tmpl_path( $self->get_config_var('tmpl_path') );
    
}


# hooking callback load_tmpl so we can
# 1) set some sane, safe template defaults
# 2) have the app set its own defaults in app.conf
# 3) allow the app to specify different options in
#    certain run modes, which will override 1) and 2)

sub lw2f_load_tmpl {
    my $self = shift;
    my $ht_params = shift;
    my $tmpl_options = { };
    
    my $default_tmpl_options = $self->get_config_var('tmpl_options');
    
    # first, load the default tmpl options into a new hash
    foreach (keys %$default_tmpl_options) {
        if (!exists $ht_params->{$_}) {
            $ht_params->{$_} = $default_tmpl_options->{$_};
        }
    }
}


sub lw2f_auto_rest_prerun {
    my $self = shift;
    my $rm = shift;
    my $q = $self->query();
    # if auto_rest is turned on,
    # we will reset the run mode to the 'runmode_REQUESTMETHOD'
    # run mode IF that run mode actually exists
    if ($self->get_config_var('auto_rest') == 1) {
        my $rqm = $q->request_method();
        if ( $self->can($rm.'_'.$rqm) ) {
            $self->prerun_mode($rm.'_'.$rqm);
        }
        # if 'runmode_REQUESTMETHOD' isn't defined,
        # we don't do anything and the normal run mode
        # will be run
    }
    # if auto_rest isn't on, we don't do _anything at all_
}


sub lw2f_load_dbi {
    my $dbi = 'DBI';
    if ( !$dbi->can('connect') ) {
        eval {
            require DBI;
            1;
        } or do {
            # rethrow error with added info
            my $E = $@;
            die('ERROR:  Could not load DBI module.  Is it installed?  '.$E);
        };
    }
}


sub lw2f_connect_databases {
    my $self = shift;    
    my $dbconfigs = shift;

    foreach my $db ( keys %$dbconfigs ) {
        my $dbh = $self->get_dbh( $db, $dbconfigs );
        $Databases->{ $db } = $dbh;
    }
}


sub get_dbh {
    my $self = shift;
    my $dbname = shift;
    my $databases = @_ ? shift : $self->get_config_var('databases');
    
    unless ( defined $databases ) {
        die("ERROR: No databases are defined in the application configuration."); #[]
    }
    
    unless ( defined $databases->{$dbname} && defined $databases->{$dbname}->{dsn} ) {
        die("ERROR: Database $dbname is not defined in the application configuration.");   #[]
    }
    
    # for convenience
    my $dbcreds = $databases->{$dbname};
    
    # we're going to modify the options, so make a copy of it to modify
    my $options = { };
    if ( defined $dbcreds->{options} ) {
        while ( my ($key, $value) = each %{ $dbcreds->{options} } ) {
            $options->{$key} = $value;
        }
    }
    # add a private 'tag' to the database options
    $options->{'private_lw2f_'.$$} = $$;
    
    my $dbh = DBI->connect_cached(
        $dbcreds->{dsn},
        $dbcreds->{user},
        $dbcreds->{password},
        $options
    );
    
    # DBI should have thrown an error, but just in case...
    unless ( defined $dbh ) {
        die('ERROR:  Error connecting to database - '.$DBI::errstr);
    }
    
    $dbh;
}


## DEFAULT RUN MODE METHODS HERE ##
## THESE SHOULD BE OVERRIDDEN BY APPLICATIONS ##

sub error {
    my $self = shift;
    my $E = @_ ? shift : '' ;
    if ($E) {
        $self->header_add(-status => '500 Internal Server Error');
        $self->header_add(-type => 'text/plain');
        return "$E";
    } else {
        $self->header_add(-status => '404 File Not Found');
        return '';
    }
}

sub index {
    my $self = shift;
    qq{
<!doctype html>
<html lang="en">
<head><title>Hello World!</title></head>
<body>
<h1>Hello World!</h1>
<p>
This is the "index" method, the default run mode for LW2F web applications. <br />
You will want to define an "index" method in your own application <br />
to override this default run mode.
</p>
</body>
</html>
    };
}



1;
__END__



=head1 AUTHOR

Logical Helion, LLC, E<lt>lhelion at cpan dot orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-7 by Logical Helion, LLC.

This library is free software; you can redistribute it and/or 
modify it under the terms of the Artistic License 2.0.  See the 
included LICENSE file for details.

This software comes with no warranty of any kind.

=cut
