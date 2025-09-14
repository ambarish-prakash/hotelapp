# frozen_string_literal: true

require 'countries'

module Procurement
  module Transformers
    class AcmeTransformer
      # Return: A RawHotel Model after sanitizing and matching inputs from JSON
      def self.transform(hotel_json)
        hotel_id = hotel_json["Id"]
        Rails.logger.info("[AcmeTransformer] Transforming hotel with id #{hotel_id}")
        
        raw_hotel = RawHotel.find_or_initialize_by(id: hotel_id)
        raw_hotel.name = hotel_json["Name"]
        raw_hotel.source = 'Acme'
        raw_hotel.raw_json = hotel_json

        destination_id = hotel_json['DestinationId']
        raw_hotel.destination = Destination.find(destination_id)

        raw_hotel.description = hotel_json["Description"].strip
        update_location(raw_hotel, hotel_json)

        Rails.logger.info("[AcmeTransformer] Hotel object #{raw_hotel}")
        return raw_hotel
      end

      def self.update_location(raw_hotel, hotel_json)
        location = raw_hotel.persisted? ? raw_hotel.location : raw_hotel.build_location

        location.latitude  = parse_float(hotel_json["Latitude"])
        puts location.latitude
        location.longitude = parse_float(hotel_json["Longitude"])
        location.address   = hotel_json["Address"].to_s.strip.presence
        location.city      = hotel_json["City"].to_s.strip.presence
        
        code = hotel_json["Country"].to_s.strip
        country = ISO3166::Country[code]
        location.country = country ? country.iso_short_name : code.presence
      end

      def self.parse_float(val)
        return nil if val.blank?
        Float(val) rescue nil
      end
    end
  end
end
