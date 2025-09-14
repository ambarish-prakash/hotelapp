# frozen_string_literal: true

module Merger
  class DescriptionMerger
    # Merges the description for the hotel.
    # It selects the longest description among all raw hotels.
    # @param hotel [Hotel] The hotel record to update.
    # @param raw_hotels [Array<RawHotel>] The raw hotel records.
    def self.merge(hotel, raw_hotels)
      descriptions = raw_hotels.map(&:description)
      longest_description = descriptions.max_by { |desc| desc.to_s.length }
      hotel.description = longest_description
    end
  end
end