class ProcurementJob < ApplicationJob
  queue_as :procurement

  retry_on(StandardError, attempts: 3)

  def perform(source)
    endpoint = fetch_endpoint!(source)
    Rails.logger.info("[ProcurementJob] Starting job source=#{source} endpoint=#{endpoint}")

    hotel_data = Procurement::Fetcher.call(endpoint)
    Rails.logger.info("[ProcurementJob] Fetched data for #{hotel_data.length} hotels from #{source}")
  
    transformer = Procurement::Transformers.for(source)
    hotel_data.each do |hotel_json|
      begin
        raw_hotel = transformer.transform(hotel_json)
        raw_hotel.save!
        # trigger a merge job
      rescue => e
        Rails.logger.warn("[ProcurementJob] Skipping item due to #{e.class}: #{e.message}")
      end
    end
  end

  def fetch_endpoint!(source)
    cfg = Rails.configuration.x.procurement_sources
    cfg[source.to_sym][:endpoint] || (raise ArgumentError, "Unknown source #{source.inspect}")
  end
end
