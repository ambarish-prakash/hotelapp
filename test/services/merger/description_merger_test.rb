require "test_helper"

class Merger::DescriptionMergerTest < ActiveSupport::TestCase
  test "should set the longest description" do
    hotel = hotels(:one)
    raw_hotels = [
      raw_hotels(:one),
      raw_hotels(:two)
    ]

    # Assuming raw_hotel_1 has a longer description
    raw_hotels[0].description = "This is a long description."
    raw_hotels[1].description = "Short desc."

    Merger::DescriptionMerger.merge(hotel, raw_hotels)

    assert_equal "This is a long description.", hotel.description
  end

  test "should set empty string if only one raw hotel has empty description" do
    hotel = hotels(:one)
    raw_hotels = [
      raw_hotels(:one)
    ]

    raw_hotels[0].description = ""

    Merger::DescriptionMerger.merge(hotel, raw_hotels)

    assert_equal "", hotel.description
  end
end
