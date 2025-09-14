# frozen_string_literal: true

module Merger
  # Service object to merge data from multiple RawHotel records into a single Hotel record.
  class HotelMerger
    # Merges data from multiple RawHotel records into a single Hotel record.
    # It finds or creates a Hotel and then calls various merge sub-methods.
    # @param hotel_code [String] The unique code for the hotel to merge.
    def self.merge(hotel_code)
      ActiveRecord::Base.transaction do
        Rails.logger.info("[Merger::HotelMerger] Starting merge of hotel data for hotel code: #{hotel_code}")
        
        raw_hotels = RawHotel.where(hotel_code: hotel_code)
        Rails.logger.info("[Merger::HotelMerger] Found #{raw_hotels.count} raw hotels for hotel code: #{hotel_code}")

        if raw_hotels.empty?
          hotel = Hotel.find_by(hotel_code: hotel_code) # Find the hotel if it exists
          if hotel.present?
            Rails.logger.info("[Merger::HotelMerger] No raw hotels found for hotel code: #{hotel_code}. Deleting existing hotel.")
            hotel.destroy!
          else
            Rails.logger.info("[Merger::HotelMerger] No raw hotels found for hotel code: #{hotel_code} and no existing hotel to delete. Returning.")
          end
          return
        end

        hotel = Hotel.find_or_initialize_by(hotel_code: hotel_code)
        Rails.logger.info("[Merger::HotelMerger] #{hotel.new_record? ? 'Building new' : 'Found existing'} hotel for hotel code: #{hotel_code}")

        # For Name and Destination, I assume that all raw_hotels have it and its the same across all
        hotel.name = raw_hotels.first.name
        hotel.destination = raw_hotels.first.destination

        Rails.logger.info("[Merger::HotelMerger] Merging description for hotel code: #{hotel_code}")
        Merger::DescriptionMerger.merge(hotel, raw_hotels)

        Rails.logger.info("[Merger::HotelMerger] Merging booking conditions for hotel code: #{hotel_code}")
        Merger::BookingConditionMerger.merge(hotel, raw_hotels)

        Rails.logger.info("[Merger::HotelMerger] Saving hotel record for hotel code: #{hotel_code}")
        hotel.save!

        # Merge other related data models
        Rails.logger.info("[Merger::HotelMerger] Merging location for hotel code: #{hotel_code}")
        Merger::LocationMerger.merge(hotel, raw_hotels)

        Rails.logger.info("[Merger::HotelMerger] Merging amenities for hotel code: #{hotel_code}")
        Merger::AmenitiesMerger.merge(hotel, raw_hotels)

        Rails.logger.info("[Merger::HotelMerger] Merging images for hotel code: #{hotel_code}")
        Merger::ImageMerger.merge(hotel, raw_hotels)

        Rails.logger.info("[Merger::HotelMerger] Completed merge of hotel data for hotel code: #{hotel_code}")
      end
    end
  end
end
