# frozen_string_literal: true

module Merger
  class AmenitiesMerger
    # Merges amenities for the hotel.
    # It identifies amenities present in a majority of the raw hotel sources.
    # @param hotel [Hotel] The hotel record to update.
    # @param raw_hotels [Array<RawHotel>] The raw hotel records.
    def self.merge(hotel, raw_hotels)
      hotel.amenities.delete_all

      # Find amenities that are present in the majority of the sources
      threshold = (raw_hotels.count + 1) / 2
      majority_amenities = Amenity.where(owner: raw_hotels)
                                  .group(:category, :name)
                                  .having("COUNT(DISTINCT owner_id) >= ?", threshold)
                                  .pluck(:category, :name)

      if majority_amenities.any?
        now = Time.current
        records_to_insert = majority_amenities.map do |category, name|
          {
            category: category,
            name: name,
            owner_id: hotel.id,
            owner_type: 'Hotel',
            created_at: now,
            updated_at: now
          }
        end
        Amenity.insert_all(records_to_insert)
      end
    end
  end
end