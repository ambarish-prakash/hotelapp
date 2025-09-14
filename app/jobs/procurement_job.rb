class ProcurementJob < ApplicationJob
  queue_as :procurement

  retry_on(StandardError, attempts: 3)

  def perform(source)
    endpoint = fetch_endpoint!(source)
    Rails.logger.info("[ProcurementJob] Starting job source=#{source} endpoint=#{endpoint}")

    hotel_data = Procurement::Fetcher.call(endpoint)
    Rails.logger.info("[ProcurementJob] Fetched data for #{hotel_data.length} hotels from #{source}")
  
    importer = Procurement::Importers.for(source)
    hotel_data.each do |hotel_json|
      begin
        raw_hotel = importer.import(hotel_json)
        Rails.logger.info("[ProcurementJob] Imported Hotel with Hotel Code #{raw_hotel.hotel_code} from Source #{raw_hotel.source}")
        # trigger a merge job
      rescue => e
        Rails.logger.warn("[ProcurementJob] Procurement for hotel #{hotel_json} failed")
        Rails.logger.warn("[ProcurementJob] Skipping item due to #{e.class}: #{e.message}")
      end
    end
    nil
  end

  def fetch_endpoint!(source)
    cfg = Rails.configuration.x.procurement_sources
    cfg[source.to_sym][:endpoint] || (raise ArgumentError, "Unknown source #{source.inspect}")
  end
end
