# frozen_string_literal: true

module Patagonia
  class HotelImporter < BaseImporter
    def self.import(hotel_json)
      ActiveRecord::Base.transaction do
        hotel_id = hotel_json["id"]
        raw_hotel = RawHotel.find_or_initialize_by(hotel_code: hotel_id, source: "Patagonia")

        raw_hotel.name = hotel_json["name"].to_s.strip
        raw_hotel.raw_json = hotel_json
        raw_hotel.destination = Destination.find(hotel_json["destination"])
        raw_hotel.description = hotel_json["info"].to_s.strip

        update_location(
          raw_hotel,
          lat: hotel_json["lat"],
          lng: hotel_json["lng"],
          address: hotel_json["address"],
          city: nil, # Not available in the JSON
          country: nil # Not available in the JSON
        )

        raw_hotel.save!

        sync_amenities(raw_hotel, hotel_json["amenities"])
        sync_images(raw_hotel, hotel_json["images"])

        raw_hotel
      end
    end
  end
end
