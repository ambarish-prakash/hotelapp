require "test_helper"

class LocationTest < ActiveSupport::TestCase
  test "should be valid with all attributes" do
    raw_hotel = raw_hotels(:two)
    location = Location.new(
      owner: raw_hotel,
      latitude: 1.23,
      longitude: 4.56,
      address: "123 Main St",
      city: "Anytown",
      country: "USA"
    )
    assert location.valid?
  end

  test "should not allow duplicate location for the same owner" do
    raw_hotel = raw_hotels(:one)
    duplicate_location = Location.new(
      owner: raw_hotel,
      address: "456 Other St"
    )

    assert_raises(ActiveRecord::RecordNotUnique) do
      duplicate_location.save(validate: false)
    end
  end

  test "should not save without an owner" do
    location = Location.new(
      latitude: 1.23,
      longitude: 4.56,
      address: "123 Main St"
    )
    assert_raises(ActiveRecord::RecordInvalid) do
      location.save!
    end
  end

  test "should be invalid with a duplicate owner" do
    raw_hotel = raw_hotels(:one) # This hotel already has a location from the fixtures
    
    duplicate_location = Location.new(
      owner: raw_hotel,
      address: "A different address"
    )

    assert_not duplicate_location.valid?
  end
end
