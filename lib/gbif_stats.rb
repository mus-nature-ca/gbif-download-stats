# encoding: utf-8

class GbifStats

  GBIF_DATASET_URL = "http://api.gbif.org/v1/occurrence/download/dataset"

  def initialize args
    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end
  end

  def dataset_results
    Enumerator.new do |yielder|
      offset = 0

      loop do
        gbif_url = "#{GBIF_DATASET_URL}/#{@uuid}?offset=#{offset}&limit=500"
        req = Typhoeus.get(gbif_url)
        result = JSON.parse(req.body, symbolize_names: true)
        if result[:results].size == 0
          raise StopIteration
        end
        result[:results].each do |r|
          num_records = r[:numberRecords]
          doi = "https://doi.org/#{r[:download][:doi].gsub(/^(?i:doi)[\=\:]?\s*/,'')}" rescue nil
          query = r[:download][:request][:predicate]
          created = r[:download][:created].to_datetime
          status = r[:download][:status]
          if status == "SUCCEEDED" && created >= start_date && created <= end_date.advance(days: 1)
            yielder << [@name, num_records, doi, query, created.strftime("%Y-%m-%d")]
          end
          if created < start_date
            raise StopIteration
          end
        end
        offset += 500
      end
    end.lazy
  end

  private

  def start_date
    Date.new(1970)
    if @start_date
      @start_date.to_datetime
    end
  end

  def end_date
    Date.today
    if @end_date
      @end_date.to_datetime
    end
  end

end