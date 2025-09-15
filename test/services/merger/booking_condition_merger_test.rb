require "test_helper"

class Merger::BookingConditionMergerTest < ActiveSupport::TestCase
  test "should merge booking conditions" do
    hotel = hotels(:one)
    raw_hotels = [
      raw_hotels(:one),
      raw_hotels(:two)
    ]

    raw_hotels[0].booking_conditions = [ "condition A", "condition B" ]
    raw_hotels[1].booking_conditions = [ "condition C", "condition D" ]

    Merger::BookingConditionMerger.merge(hotel, raw_hotels)

    expected_conditions = [ "condition A", "condition B", "condition C", "condition D" ]
    assert_equal expected_conditions.sort, hotel.booking_conditions.sort
  end

  test "should handle empty booking conditions arrays" do
    hotel = hotels(:one)
    raw_hotels = [
      raw_hotels(:one),
      raw_hotels(:two)
    ]

    raw_hotels[0].booking_conditions = []
    raw_hotels[1].booking_conditions = []

    Merger::BookingConditionMerger.merge(hotel, raw_hotels)

    assert_empty hotel.booking_conditions

    # If only one is empty
    raw_hotels[0].booking_conditions = [ "condition A" ]

    Merger::BookingConditionMerger.merge(hotel, raw_hotels)

    assert_equal [ "condition A" ], hotel.booking_conditions
  end

  test "should deduplicate booking conditions" do
    hotel = hotels(:one)
    raw_hotels = [
      raw_hotels(:one),
      raw_hotels(:two)
    ]

    raw_hotels[0].booking_conditions = [ "condition A", "condition B" ]
    raw_hotels[1].booking_conditions = [ "condition B", "condition C" ]

    Merger::BookingConditionMerger.merge(hotel, raw_hotels)

    expected_conditions = [ "condition A", "condition B", "condition C" ]
    assert_equal expected_conditions.sort, hotel.booking_conditions.sort
  end
end
