require "test_helper"

class HotelTest < ActiveSupport::TestCase
  test "should be valid with all attributes" do
    destination = destinations(:one)
    hotel = Hotel.new(
      destination: destination,
      hotel_code: "test_hotel",
      name: "Test Hotel",
      description: "Test Description",
      booking_conditions: "Test Booking Conditions"
    )
    assert hotel.valid?
  end

  test "should not allow duplicate hotel_code" do
    destination = destinations(:one)
    Hotel.create!(
      destination: destination,
      hotel_code: "test_hotel",
      name: "Test Hotel"
    )

    duplicate_hotel = Hotel.new(
      destination: destination,
      hotel_code: "test_hotel",
      name: "Another Test Hotel"
    )

    assert_raises(ActiveRecord::RecordNotUnique) do
      duplicate_hotel.save(validate: false)
    end
  end

  test "should not be valid without a destination" do
    hotel = Hotel.new(
      hotel_code: "test_hotel",
      name: "Test Hotel"
    )
    assert_not hotel.valid?
  end

  test "should not be valid without a hotel_code" do
    destination = destinations(:one)
    hotel = Hotel.new(
      destination: destination,
      name: "Test Hotel"
    )
    assert_not hotel.valid?
  end

  test "should destroy associated records when destroyed" do
    hotel = Hotel.create!(
      destination: destinations(:one),
      hotel_code: "test_hotel_for_destroy",
      name: "Test Hotel"
    )
    hotel.amenities.create!(category: "general", name: "pool")
    hotel.images.create!(category: "rooms", url: "http://example.com/image.jpg")
    hotel.create_location!(address: "123 Main St")

    assert_difference ["Amenity.count", "Image.count", "Location.count"], -1 do
      hotel.destroy
    end
  end
end
