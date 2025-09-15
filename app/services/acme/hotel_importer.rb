# frozen_string_literal: true

require "countries"

module Acme
  class HotelImporter < BaseImporter
    def self.import(hotel_json)
      ActiveRecord::Base.transaction do
        hotel_id = hotel_json["Id"]
        raw_hotel = RawHotel.find_or_initialize_by(hotel_code: hotel_id, source: "Acme")

        raw_hotel.name = hotel_json["Name"].to_s.strip
        raw_hotel.raw_json = hotel_json
        raw_hotel.destination = Destination.find(hotel_json["DestinationId"])
        raw_hotel.description = hotel_json["Description"].to_s.strip

        country_code = hotel_json["Country"].to_s.strip.upcase
        country = ISO3166::Country[country_code]

        update_location(
          raw_hotel,
          lat: hotel_json["Latitude"],
          lng: hotel_json["Longitude"],
          address: hotel_json["Address"],
          city: hotel_json["City"],
          country: country ? country.iso_short_name : country_code
        )

        raw_hotel.save!

        sync_amenities(raw_hotel, hotel_json["Facilities"])

        raw_hotel
      end
    end
  end
end
