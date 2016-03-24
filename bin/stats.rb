#!/usr/bin/env ruby
# encoding: utf-8
require_relative '../environment.rb'

ARGV << '-h' if ARGV.empty?

options = {}

uuids = {
  herbarium: '830da118-f762-11e1-a439-00145eb45e9a',
  mollusc: '830c7b08-f762-11e1-a439-00145eb45e9a',
  amphibian_reptile: '830a1f84-f762-11e1-a439-00145eb45e9a',
  bird: '8309005e-f762-11e1-a439-00145eb45e9a',
  fish: '830b4af8-f762-11e1-a439-00145eb45e9a'
}

OptionParser.new do |opts|
  opts.banner = "Usage: stats.rb [options]"

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end

  opts.on("-a", "--all", "Calculates all stats") do |a|
    options[:all] = true
  end
  
  opts.on("-d", "--uuid [UUID]", String, "Include the UUID of the dataset") do |uuid|
    options[:uuid] = uuid
  end

end.parse!

if options[:all]
  pbar = ProgressBar.new("STATS", uuids.count)
  output_dir = File.dirname(File.dirname(__FILE__)) + "/output/"
  counter = 0
  uuids.each do |key,uuid|
    counter += 1
    pbar.set(counter)
    response = RestClient::Request.execute(
      method: :get,
      url: "http://api.gbif.org/v1/occurrence/download/dataset/#{uuid}?offset=0&limit=500",
    )
    results = JSON.parse(response, :symbolize_names => true)[:results]
    CSV.open(output_dir + "gbif_cmn_stats_#{key}_#{Date.today.to_s}.csv", 'w') do |csv|
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
elsif options[:uuid]
  puts "Sorry, not yet implemented"
end