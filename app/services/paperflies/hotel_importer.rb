# frozen_string_literal: true

module Paperflies
  class HotelImporter < BaseImporter
    # Imports hotel data from the Paperflies source.
    #
    # @param hotel_json [Hash] The hotel data from the Paperflies API.
    # @return [RawHotel] The imported raw hotel record.
    def self.import(hotel_json)
      ActiveRecord::Base.transaction do
        hotel_id = hotel_json["hotel_id"]
        raw_hotel = RawHotel.find_or_initialize_by(hotel_code: hotel_id, source: "Paperflies")

        raw_hotel.name = hotel_json["hotel_name"].to_s.strip
        raw_hotel.raw_json = hotel_json
        raw_hotel.destination = Destination.find(hotel_json["destination_id"])
        raw_hotel.description = hotel_json["details"].to_s.strip
        raw_hotel.booking_conditions = (hotel_json["booking_conditions"] || []).map(&:strip)

        location_data = hotel_json["location"] || {}
        update_location(
          raw_hotel,
          lat: nil, # Not available
          lng: nil, # Not available
          address: location_data["address"].to_s.strip,
          city: nil, # Not available
          country: location_data["country"].to_s.strip
        )

        raw_hotel.save!

        amenities = (hotel_json.dig("amenities", "general") || []) + (hotel_json.dig("amenities", "room") || [])
        sync_amenities(raw_hotel, amenities)

        images_data = hotel_json["images"] || {}
        formatted_images = {}
        images_data.each do |category, images|
          formatted_images[category] = images.map do |image|
            { "url" => image["link"], "description" => image["caption"] }
          end
        end
        sync_images(raw_hotel, formatted_images)

        raw_hotel
      end
    end
  end
end
