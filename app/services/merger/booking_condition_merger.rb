# frozen_string_literal: true

module Merger
  class BookingConditionMerger
    # Merges booking conditions for the hotel.
    # It collects all unique booking conditions from all raw hotels.
    # @param hotel [Hotel] The hotel record to update.
    # @param raw_hotels [Array<RawHotel>] The raw hotel records.
    def self.merge(hotel, raw_hotels)
      all_booking_conditions = raw_hotels.flat_map(&:booking_conditions).compact.uniq
      hotel.booking_conditions = all_booking_conditions
    end
  end
end