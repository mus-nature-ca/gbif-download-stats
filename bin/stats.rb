#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'

options = {}

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: stats.rb [options]"

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
  
  opts.on("-c", "--config [FILE]", String, "Include a full path to the config.yml file") do |config|
    options[:config] = config
  end

  opts.on("-o", "--output [DIRECTORY]", String, "Directory for the output files") do |directory|
    options[:output_dir] = directory
  end
end

begin
  optparse.parse!
  if options[:config]
    config_file = options[:config]
  else
    config_file = File.join(File.dirname(File.dirname(__FILE__)), 'config.yml')
  end
  raise "File not found" unless File.exists?(config_file)

  if options[:output_dir]
    output_dir = options[:output_dir]
  else
    output_dir = File.join(File.dirname(File.dirname(__FILE__)), "output")
  end
  raise "Directory not found" unless Dir.exists?(output_dir)

  config = YAML.load_file(config_file)
  pbar = ProgressBar.new("STATS", config.size)
  counter = 0
  config.each do |item|
    key = item[0]
    uuid = item[1]["uuid"]
    numlines = item[1]["lines"]

    counter += 1
    pbar.set(counter)
    response = RestClient::Request.execute(
      method: :get,
      url: "http://api.gbif.org/v1/occurrence/download/dataset/#{uuid}?offset=0&limit=#{numlines}",
    )
    results = JSON.parse(response, :symbolize_names => true)[:results]
    CSV.open(File.join(output_dir, "gbif_stats_#{key}.csv"), 'w') do |csv|
      csv << ["download_num_records", "download_doi", "created"]
      results.each do |result|
        download_num_records = result[:numberRecords]
        download_doi = "http://doi.org/#{result[:download][:doi].gsub(/^(?i:doi)[\=\:]?\s*/,'')}"
        created = result[:download][:created]
        status = result[:download][:status]
        if status == "SUCCEEDED"
          csv << [download_num_records, download_doi, created]
        end
      end
    end
  end
  pbar.finish
rescue
  puts $!.to_s
  puts optparse
  exit 
end