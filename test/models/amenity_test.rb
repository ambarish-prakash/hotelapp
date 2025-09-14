require "test_helper"

class AmenityTest < ActiveSupport::TestCase
  test "should be valid with all attributes" do
    raw_hotel = raw_hotels(:one)
    amenity = Amenity.new(
      owner: raw_hotel,
      category: "general",
      name: "wifi"
    )
    assert amenity.valid?
  end

  test "should not allow duplicate amenity for the same owner" do
    raw_hotel = raw_hotels(:one)
    Amenity.create!(
      owner: raw_hotel,
      category: "general",
      name: "wifi"
    )

    duplicate_amenity = Amenity.new(
      owner: raw_hotel,
      category: "general",
      name: "wifi"
    )

    assert_raises(ActiveRecord::RecordNotUnique) do
      duplicate_amenity.save(validate: false)
    end
  end

  test "should allow same amenity for different owners" do
    raw_hotel_one = raw_hotels(:one)
    raw_hotel_two = raw_hotels(:two)

    Amenity.create!(
      owner: raw_hotel_one,
      category: "general",
      name: "wifi"
    )

    other_amenity = Amenity.new(
      owner: raw_hotel_two,
      category: "general",
      name: "wifi"
    )

    assert other_amenity.valid?
  end

  test "should not be valid without an owner" do
    amenity = Amenity.new(
      category: "general",
      name: "wifi"
    )
    assert_not amenity.valid?
  end
end
