Consume Dataset Statistics from the GBIF API
============================================

Basic ruby-based script to gather download event statistics from the [Global Biodiversity Information Facility](http://www.gbif.org/) (GBIF) [API](http://www.gbif.org/developer/summary) for specified datasets (using known GBIF UUIDs) and produce csv files. Adjust the content of config.yml.sample and rename config.yml then execute:

          $ gem install bundler
          $ bundle install
          $ ./bin/stats.rb --help

Requirements
------------
ruby 2.3.0

Contact
-------
David P. Shorthouse, <dshorthouse@mus-nature.ca>