inDoc
=====

inDoc is a little tool to discover your Icinga monitoring environment.

Installation
------------

    # git clone https://github.com/netways/inDoc.git <home-of-monitoring-user>/inDoc
    
In most setups inDoc runs out of the box. If you have a very minimal installation you mabe need to install the perl modules 'Time::HiRes' and 'Module::Load'

Usage
-----

    # su - <monitoring-user>
    # cd inDoc/
    # ./inDoc.pl

Options
-------

* -o|--output <output dir>

    Specify a output dir you want inDoc to store the discovery data.

    Default: /tmp/inDoc-out

* -a|--additional <path1,path2,path3>

    Specify a comma seperated list of full qualified paths for inDoc discoveries. It's helpfull if your monitoring environment runs in a custom path like '/opt/monitoring-foo'.

* -i|--include <module1,module2,module3>

    Specify a comma seperated list of modules you want to run for discovery.

* -e|--execlude <module1,module2,module3>

    Specify a comma seperated list of modules you don't want to run during discovery.

* -l|--list

    List all available modules
