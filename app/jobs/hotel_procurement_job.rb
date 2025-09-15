class HotelProcurementJob < ApplicationJob
  queue_as :procurement

  retry_on(StandardError, attempts: 3)

  # Fetches hotel data from a source, imports it, and triggers a merge job.
  #
  # @param source [String] The procurement source (e.g., 'acme', 'paperflies').
  def perform(source)
    endpoint = fetch_endpoint!(source)
    Rails.logger.info("[HotelProcurementJob] Starting job source=#{source} endpoint=#{endpoint}")

    hotel_data = Procurement::Fetcher.call(endpoint)
    Rails.logger.info("[HotelProcurementJob] Fetched data for #{hotel_data.length} hotels from #{source}")

    importer = Procurement::Importers.for(source)
    processed_hotel_codes = []

    hotel_data.each do |hotel_json|
      begin
        raw_hotel = importer.import(hotel_json)
        processed_hotel_codes << raw_hotel.hotel_code
        Rails.logger.info("[HotelProcurementJob] Imported Hotel with Hotel Code #{raw_hotel.hotel_code} from Source #{raw_hotel.source}")

        HotelMergeJob.perform_later(raw_hotel.hotel_code)
        Rails.logger.info("[HotelProcurementJob] Triggered HotelMergeJob for Hotel Code #{raw_hotel.hotel_code}")
      rescue => e
        Rails.logger.warn("[HotelProcurementJob] Procurement for hotel #{hotel_json} failed")
        Rails.logger.warn("[HotelProcurementJob] Skipping item due to #{e.class}: #{e.message}")
      end
    end

    # Prune stale records
    stale_hotels = RawHotel.where(source: source).where.not(hotel_code: processed_hotel_codes)
    if stale_hotels.any?
      stale_hotel_codes = stale_hotels.pluck(:hotel_code)
      stale_hotels.delete_all
      Rails.logger.info("[HotelProcurementJob] Pruned #{stale_hotel_codes.count} stale RawHotel records for source #{source}: #{stale_hotel_codes.join(', ')}")

      # Trigger merge jobs for the pruned hotels
      stale_hotel_codes.each do |hotel_code|
        HotelMergeJob.perform_later(hotel_code)
        Rails.logger.info("[HotelProcurementJob] Triggered HotelMergeJob for pruned Hotel Code #{hotel_code}")
      end
    end

    nil
  end

  private

  # Fetches the endpoint URL for a given source from the configuration.
  #
  # @param source [String] The procurement source.
  # @return [String] The endpoint URL.
  # @raise [ArgumentError] if the source is unknown.
  def fetch_endpoint!(source)
    cfg = Rails.configuration.x.procurement_sources
    cfg[source.to_sym][:endpoint] || (raise ArgumentError, "Unknown source #{source.inspect}")
  end
end
