# inDoc module development guide

## Module Basics
Every module consists two files. A config file (.ini) and perl package (.pm).

## Config file example
    [myfancymodule]
    ; some fancy vars you need for your module
    fancyvar = very fancy content
    
This file is named 'myfancymodule.ini' and is located in <inDoc-path>/doc.d/

## Perl package example
    package myfancymodule;
    
    # includes
    use lib qw(lib ../lib .. doc.d);
    use strict;
    use File::Basename;
    use inDoc::ConfigReader;

    # package information
    our $pkg;
    $pkg->{name}        = 'myfancymodule';
    $pkg->{version}     = '0.1';
    $pkg->{description} = 'fancy module description';

This file is named 'myfancymodule.pm' and is located in <inDoc-path>/doc.d/

## inDoc variables and functions
For easier use inDoc provides some default variables and functions. To use / import them just paste these lines into your module:

    # map variables from inDoc.pm --> easier handling and typing
    my $msg = $inDoc::msg;
    my $cfg = $inDoc::cfg;
    my $dcy = $inDoc::discovery;
    my $hlp = $inDoc::helper;
    
### $inDoc::msg (message handler)
The message handler takes care about your output. It handles timestamps, exit codes, etc.

* $msg->info('this is my info message');
* $msg->verbose('this is my verbose message');
* $msg->warning('this is my warning message');
* $msg->error('this is my error message');

You'll get a output like this:

    2015-05-04 10:59:39 | INFO: this is my info message
    
### $inDoc::cfg (config reader)
The config reader provides some little functions to handle the ini config files.

* $cfg->load('path-to-myfancymodule.ini');

    Load an inDoc config ini file; config will be converted to a hashref.
    
    Example: If your config look like this...
    
        [myfancymodule]
        fancyvar = very fancy content
        
    ...you will get an hashref with...
        $cfg->{myfancymodule}->{fancyvar} = 'very fancy content';
    
* $cfg->dump();

    Print loaded config to STDOUT.

### $inDoc::discovery (discovery handler)

* $dcy->store('name', 'value'); 

    Store discovered data 'bar' in a hashref with the key 'foo'.
    
* $dcy->get(); 

    Get stored data as hashref.
    
* $dcy->dump();

Print stored data in hashref format (to STDOUT)

* $dcy->getModules(); 

Get a list of all available modules. Function will return an array.

* $dcy->list();

Print a list of all available modules (to STDOUT)

### $inDoc::helper (helper functions)

* $hlp->execCMD('date');

    Execute a command and return the result in an array.
  
* $hlp->getProcessByName('^/usr/sbin/icinga -d');

    Returns a hasref of processes. Return values can be filtered with regex (optional).
  
* $hlp->getFileStats('/etc/icinga/icinga.cfg'); 

    Returns file stats of a specified file as hashref.
    
    Sample return values:

        $filestats->{path} = '/etc/icinga/icinga.cfg';
        $filestats->{permissions} = '-rw-r--r--';
        $filestats->{user} = 'icingauser';
        $filestats->{group} = 'icingagroup';
        $filestats->{size} = '48K';
        $filestats->{modified} = 'Jan 4 16:18';
        
* $hlp->find('icinga.cfg', '/etc');

    Returns an array with found files
    
* $hlp->saveFile('/etc/icinga/icinga.cfg');

    Save specified file in inDoc output dir.
    
* $hlp->getMemoryStatus();

    Returns a hasref of /proc/meminfo. Return values can be filtered with regex (optional).
    
* $hlp->getOSType();

    Returns a hashref with OS type and version.
