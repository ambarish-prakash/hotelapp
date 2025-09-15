require "test_helper"

class Merger::LocationMergerTest < ActiveSupport::TestCase
  setup do
    @hotel = hotels(:one)
    @hotel.create_location! unless @hotel.location.present?

    @raw_hotel_1 = raw_hotels(:one)
    @raw_hotel_1.create_location! unless @raw_hotel_1.location.present?

    @raw_hotel_2 = raw_hotels(:two)
    @raw_hotel_2.create_location! unless @raw_hotel_2.location.present?

    # Ensure raw_hotels have distinct updated_at for prioritization tests
    @raw_hotel_1.update!(updated_at: 2.days.ago)
    @raw_hotel_2.update!(updated_at: 1.day.ago)
  end

  test "should merge latitude and longitude from the most recently updated raw hotel" do
    @raw_hotel_1.location.update!(latitude: 10.0, longitude: 20.0)
    @raw_hotel_2.location.update!(latitude: 11.0, longitude: 21.0)

    Merger::LocationMerger.merge(@hotel, [ @raw_hotel_1, @raw_hotel_2 ])

    assert_equal 11.0, @hotel.location.latitude
    assert_equal 21.0, @hotel.location.longitude
  end

  test "should merge address from the most recently updated raw hotel" do
    @raw_hotel_1.location.update!(address: "Old Address")
    @raw_hotel_2.location.update!(address: "New Address")

    Merger::LocationMerger.merge(@hotel, [ @raw_hotel_1, @raw_hotel_2 ])

    assert_equal "New Address", @hotel.location.address
  end

  test "should merge city from the most recently updated raw hotel" do
    @raw_hotel_1.location.update!(city: "Old City")
    @raw_hotel_2.location.update!(city: "New City")

    Merger::LocationMerger.merge(@hotel, [ @raw_hotel_1, @raw_hotel_2 ])

    assert_equal "New City", @hotel.location.city
  end

  test "should merge country from the most recently updated raw hotel" do
    @raw_hotel_1.location.update!(country: "Old Country")
    @raw_hotel_2.location.update!(country: "New Country")

    Merger::LocationMerger.merge(@hotel, [ @raw_hotel_1, @raw_hotel_2 ])

    assert_equal "New Country", @hotel.location.country
  end

  test "should create a new location if one does not exist" do
    @hotel.location = nil # Ensure no existing location
    @hotel.save!

    @raw_hotel_1.location.update!(latitude: 10.0, longitude: 20.0, address: "Address", city: "City", country: "Country")

    assert_nil @hotel.location

    Merger::LocationMerger.merge(@hotel, [ @raw_hotel_1 ])

    assert_not_nil @hotel.location
    assert_equal 10.0, @hotel.location.latitude
    assert_equal "Address", @hotel.location.address
  end

  test "should update an existing location" do
    existing_location = @hotel.create_location(latitude: 1.0, longitude: 2.0, address: "Initial Address")
    @hotel.save!

    @raw_hotel_1.location.update!(latitude: 10.0, longitude: 20.0, address: "Updated Address")

    Merger::LocationMerger.merge(@hotel, [ @raw_hotel_1 ])

    assert_equal existing_location.id, @hotel.location.id
    assert_equal 10.0, @hotel.location.latitude
    assert_equal "Updated Address", @hotel.location.address
  end

  test "should handle raw hotels with no location data" do
    @hotel.location = nil
    @hotel.save!

    @raw_hotel_1.location.update!(latitude: nil, longitude: nil, address: nil, city: nil, country: nil)
    @raw_hotel_2.location.update!(latitude: nil, longitude: nil, address: nil, city: nil, country: nil)

    Merger::LocationMerger.merge(@hotel, [ @raw_hotel_1, @raw_hotel_2 ])

    assert_nil @hotel.location.latitude
    assert_nil @hotel.location.longitude
    assert_equal "", @hotel.location.address
    assert_equal "", @hotel.location.city
    assert_equal "", @hotel.location.country
  end

  test "should pick the most recent non-empty values" do
    @raw_hotel_1.location.update!(latitude: 10.0, longitude: 20.0, address: "Address 1", city: "City 1", country: "Country 1", updated_at: 2.days.ago)
    @raw_hotel_2.location.update!(latitude: nil, longitude: nil, address: "Address 2", city: "City 2", country: "Country 2", updated_at: 1.day.ago)

    Merger::LocationMerger.merge(@hotel, [ @raw_hotel_1, @raw_hotel_2 ])

    assert_equal 10.0, @hotel.location.latitude
    assert_equal 20.0, @hotel.location.longitude
    assert_equal "Address 2", @hotel.location.address
    assert_equal "City 2", @hotel.location.city
    assert_equal "Country 2", @hotel.location.country
  end
end
