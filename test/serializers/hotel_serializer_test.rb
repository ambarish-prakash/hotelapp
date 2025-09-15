require "test_helper"

class HotelSerializerTest < ActiveSupport::TestCase
  setup do
    @hotel = hotels(:one)
    @serializer = HotelSerializer.new(@hotel)
    @serialization = @serializer.as_json
  end

  test "serializes id, destination_id, name, description, and booking_conditions" do
    assert_equal @hotel.hotel_code, @serialization[:id]
    assert_equal @hotel.destination_id, @serialization[:destination_id]
    assert_equal @hotel.name, @serialization[:name]
    assert_equal @hotel.description, @serialization[:description]
    assert_equal @hotel.booking_conditions, @serialization[:booking_conditions]
  end

  test "serializes location using LocationSerializer" do
    assert_not_nil @serialization[:location]
    assert_equal @hotel.location.address, @serialization[:location][:address]
    assert_equal @hotel.location.city, @serialization[:location][:city]
    assert_equal @hotel.location.country, @serialization[:location][:country]
    assert_equal @hotel.location.latitude, @serialization[:location][:lat]
    assert_equal @hotel.location.longitude, @serialization[:location][:lng]
  end

  test "serializes amenities grouped by category" do
    assert_not_nil @serialization[:amenities]
    assert_instance_of Hash, @serialization[:amenities]
    assert_equal [ "bar", "wifi" ].sort, @serialization[:amenities]["general"].sort
    assert_equal [ "aircon" ].sort, @serialization[:amenities]["room"].sort
  end

  test "serializes images grouped by category with link and description" do
    assert_not_nil @serialization[:images]
    assert_instance_of Hash, @serialization[:images]

    expected_site_images = [
      { link: "http://example.com/hotel_site_1.jpg", description: "Hotel exterior" }
    ]
    expected_room_images = [
      { link: "http://example.com/hotel_room_1.jpg", description: "Deluxe room" }
    ]

    assert_equal expected_site_images.sort_by { |h| h[:link] }, @serialization[:images]["site"].sort_by { |h| h[:link] }
    assert_equal expected_room_images.sort_by { |h| h[:link] }, @serialization[:images]["room"].sort_by { |h| h[:link] }
  end
end
