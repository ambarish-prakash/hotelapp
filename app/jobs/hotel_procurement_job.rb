class HotelProcurementJob < ApplicationJob
  queue_as :procurement

  retry_on(StandardError, attempts: 3)

  def perform(source)
    endpoint = fetch_endpoint!(source)
    Rails.logger.info("[HotelProcurementJob] Starting job source=#{source} endpoint=#{endpoint}")

    hotel_data = Procurement::Fetcher.call(endpoint)
    Rails.logger.info("[HotelProcurementJob] Fetched data for #{hotel_data.length} hotels from #{source}")
  
    importer = Procurement::Importers.for(source)
    hotel_data.each do |hotel_json|
      begin
        raw_hotel = importer.import(hotel_json)
        Rails.logger.info("[HotelProcurementJob] Imported Hotel with Hotel Code #{raw_hotel.hotel_code} from Source #{raw_hotel.source}")
        
        HotelMergeJob.perform_later(raw_hotel.hotel_code)
        Rails.logger.info("[HotelProcurementJob] Triggered HotelMergeJob for Hotel Code #{raw_hotel.hotel_code}")
      rescue => e
        Rails.logger.warn("[HotelProcurementJob] Procurement for hotel #{hotel_json} failed")
        Rails.logger.warn("[HotelProcurementJob] Skipping item due to #{e.class}: #{e.message}")
      end
    end
    nil
  end

  def fetch_endpoint!(source)
    cfg = Rails.configuration.x.procurement_sources
    cfg[source.to_sym][:endpoint] || (raise ArgumentError, "Unknown source #{source.inspect}")
  end
end
