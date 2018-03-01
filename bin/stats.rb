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

  opts.on("-s", "--start-date [DATE]", String, "Start date in the form YYYY-MM-DD") do |date|
    options[:start_date] = date
  end

  opts.on("-e", "--end-date [DATE]", String, "End date in the form YYYY-MM-DD") do |date|
    options[:end_date] = date
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

  start_date = Date.new(1970)
  if options[:start_date]
    start_date = options[:start_date].to_datetime
  end

  end_date = Date.today
  if options[:end_date]
    end_date = options[:end_date].to_datetime
  end

  config = YAML.load_file(config_file)
  pbar = ProgressBar.create(
    title: "GBIF-STATS",
    total: config.size,
    autofinish: false,
    format: '%t %b>> %i| %e'
    )

  date_range = [start_date.strftime("%Y-%m-%d").to_s, end_date.strftime("%Y-%m-%d").to_s].join("-")

  CSV.open(File.join(output_dir, "gbif_stats_#{date_range}.csv"), 'w') do |csv|
    csv << ["name", "num_records", "doi", "query", "created"]

    config.each do |item|
      name = item[0]
      uuid = item[1]["uuid"]
      numlines = item[1]["lines"]
      pbar.increment
      response = RestClient::Request.execute(
        method: :get,
        url: "http://api.gbif.org/v1/occurrence/download/dataset/#{uuid}?offset=0&limit=#{numlines}",
      )
      results = JSON.parse(response, :symbolize_names => true)[:results]
      results.each do |result|
        num_records = result[:numberRecords]
        doi = "https://doi.org/#{result[:download][:doi].gsub(/^(?i:doi)[\=\:]?\s*/,'')}" rescue nil
        query = result[:download][:request][:predicate]
        created = result[:download][:created].to_datetime
        status = result[:download][:status]
        if status == "SUCCEEDED" && created >= start_date && created <= end_date.advance(days: 1)
          csv << [name, num_records, doi, query, created.strftime("%Y-%m-%d")]
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