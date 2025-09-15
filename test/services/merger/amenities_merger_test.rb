require "test_helper"

class Merger::AmenitiesMergerTest < ActiveSupport::TestCase
  setup do
    @hotel = hotels(:one)
    @raw_hotel_1 = raw_hotels(:one)
    @raw_hotel_2 = raw_hotels(:two)
    @raw_hotel_3 = raw_hotels(:three)

    # Ensure raw_hotels have distinct updated_at for prioritization tests
    @raw_hotel_1.update!(updated_at: 3.days.ago)
    @raw_hotel_2.update!(updated_at: 2.days.ago)
    @raw_hotel_3.update!(updated_at: 1.day.ago)

    # Clear existing amenities for the hotel to ensure a clean slate for each test
    @hotel.amenities.delete_all
  end

  test "should merge majority amenities correctly" do
    # Amenities for raw_hotel_1
    Amenity.create!(owner: @raw_hotel_1, category: "room", name: "TV")
    Amenity.create!(owner: @raw_hotel_1, category: "room", name: "Wifi")

    # Amenities for raw_hotel_2
    Amenity.create!(owner: @raw_hotel_2, category: "room", name: "TV")
    Amenity.create!(owner: @raw_hotel_2, category: "room", name: "Bathtub")

    # Amenities for raw_hotel_3
    Amenity.create!(owner: @raw_hotel_3, category: "room", name: "TV")
    Amenity.create!(owner: @raw_hotel_3, category: "general", name: "Outdoor Pool")

    Merger::AmenitiesMerger.merge(@hotel, [ @raw_hotel_1, @raw_hotel_2, @raw_hotel_3 ])
    @hotel.reload

    assert_equal 1, @hotel.amenities.count
    assert_equal "TV", @hotel.amenities.first.name
    assert_equal "room", @hotel.amenities.first.category
  end

  test "should remove old amenities and not insert new ones if raw hotels don't have them" do
    # Add an initial amenity to the hotel that should be removed
    Amenity.create!(owner: @hotel, category: "old", name: "Old Amenity")

    # Raw hotels have no amenities that would meet the majority threshold (2 in this case)
    Amenity.create!(owner: @raw_hotel_1, category: "room", name: "Wifi")
    Amenity.create!(owner: @raw_hotel_2, category: "room", name: "TV")
    Amenity.create!(owner: @raw_hotel_3, category: "room", name: "Balcony")

    Merger::AmenitiesMerger.merge(@hotel, [ @raw_hotel_1, @raw_hotel_2, @raw_hotel_3 ])

    assert_empty @hotel.amenities
  end

  test "should handle no majority amenities" do
    # Raw hotels have amenities, but none meet the majority threshold
    Amenity.create!(owner: @raw_hotel_1, category: "room", name: "Wifi")
    Amenity.create!(owner: @raw_hotel_2, category: "room", name: "TV")
    Amenity.create!(owner: @raw_hotel_3, category: "room", name: "Balcony")

    Merger::AmenitiesMerger.merge(@hotel, [ @raw_hotel_1, @raw_hotel_2, @raw_hotel_3 ])

    assert_empty @hotel.amenities
  end

  test "should handle amenities with different categories" do
    Amenity.create!(owner: @raw_hotel_1, category: "room", name: "TV")
    Amenity.create!(owner: @raw_hotel_1, category: "property", name: "Parking")

    Amenity.create!(owner: @raw_hotel_2, category: "room", name: "TV")
    Amenity.create!(owner: @raw_hotel_2, category: "property", name: "Parking")

    Amenity.create!(owner: @raw_hotel_3, category: "room", name: "TV")
    Amenity.create!(owner: @raw_hotel_3, category: "property", name: "Parking")

    Merger::AmenitiesMerger.merge(@hotel, [ @raw_hotel_1, @raw_hotel_2, @raw_hotel_3 ])
    @hotel.reload

    assert_equal 2, @hotel.amenities.count
    assert_equal [ [ "property", "Parking" ], [ "room", "TV" ] ].sort, @hotel.amenities.pluck(:category, :name).sort
  end
end
