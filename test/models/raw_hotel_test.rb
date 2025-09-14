require "test_helper"

class RawHotelTest < ActiveSupport::TestCase
  test "should be valid with all attributes" do
    destination = destinations(:one)
    raw_hotel = RawHotel.new(
      destination: destination,
      hotel_code: "test_hotel",
      source: "test_source",
      name: "Test Hotel",
      description: "Test Description",
      booking_conditions: "Test Booking Conditions",
      raw_json: {}
    )
    assert raw_hotel.valid?
  end

  test "should not allow duplicate hotel_code and source" do
    destination = destinations(:one)
    RawHotel.create!(
      destination: destination,
      hotel_code: "test_hotel",
      source: "test_source",
      name: "Test Hotel"
    )

    duplicate_raw_hotel = RawHotel.new(
      destination: destination,
      hotel_code: "test_hotel",
      source: "test_source",
      name: "Another Test Hotel"
    )

    assert_raises(ActiveRecord::RecordNotUnique) do
      duplicate_raw_hotel.save(validate: false)
    end
  end

  test "should not be valid without a destination" do
    raw_hotel = RawHotel.new(
      hotel_code: "test_hotel",
      source: "test_source",
      name: "Test Hotel"
    )
    assert_not raw_hotel.valid?
  end

  test "should not be valid without a hotel_code" do
    destination = destinations(:one)
    raw_hotel = RawHotel.new(
      destination: destination,
      source: "test_source",
      name: "Test Hotel"
    )
    assert_not raw_hotel.valid?
  end

  test "should destroy associated records when destroyed" do
    raw_hotel = RawHotel.create!(
      destination: destinations(:one),
      hotel_code: "test_hotel_for_destroy",
      source: "test_source"
    )
    raw_hotel.amenities.create!(category: "general", name: "pool")
    raw_hotel.images.create!(category: "rooms", url: "http://example.com/image.jpg")
    raw_hotel.create_location!(address: "123 Main St")

    assert_difference ["Amenity.count", "Image.count", "Location.count"], -1 do
      raw_hotel.destroy
    end
  end
end
