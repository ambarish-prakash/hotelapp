# frozen_string_literal: true

module Merger
  class LocationMerger
    # Merges location data (latitude, longitude, address, city, country) for the hotel.
    # It prioritizes the most recently updated raw hotel data for each attribute.
    # @param hotel [Hotel] The hotel record to update.
    # @param raw_hotels [Array<RawHotel>] The raw hotel records.
    def self.merge(hotel, raw_hotels)
      # Setup location
      if hotel.location.present?
        location = hotel.location
      else
        location = hotel.build_location
      end

      sorted_raw_hotel_locations = raw_hotels.sort_by(&:updated_at).reverse.map(&:location)

      # Set Latitude and Longitude
      # Find the most recently updated raw_hotel with valid latitude and longitude
      coord_raw_hotel_location = sorted_raw_hotel_locations.find do |loc|
        loc.latitude.present? && loc.longitude.present?
      end

      if coord_raw_hotel_location
        location.latitude = coord_raw_hotel_location.latitude
        location.longitude = coord_raw_hotel_location.longitude
      end

      # Set Address
      # Find the most recently updated raw hotel with address
      address_raw_hotel_location = sorted_raw_hotel_locations.find do |loc|
        loc.address.present?
      end

      location.address = address_raw_hotel_location ? address_raw_hotel_location.address : ""

      # Set City and Country
      # Find the most recently updated raw hotel with city and country
      city_raw_hotel_location = sorted_raw_hotel_locations.find do |loc|
        loc.city.present?
      end

      location.city = city_raw_hotel_location ? city_raw_hotel_location.city : ""

      country_raw_hotel_location = sorted_raw_hotel_locations.find do |loc|
        loc.country.present?
      end

      location.country = country_raw_hotel_location ? country_raw_hotel_location.country : ""

      hotel.location.save!
    end
  end
end
