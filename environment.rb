require 'optparse'
require 'bundler'
require 'typhoeus'
require 'json'
require 'ruby-progressbar'
require 'csv'
require 'date'
require 'yaml'
require 'active_support/all'
require 'byebug'

Dir[File.dirname(__FILE__) + "/lib/*.rb"].each{ |file| require file }