require "test_helper"

class Acme::HotelImporterTest < ActiveSupport::TestCase
  setup do
    @destination = destinations(:one)
  end

  test "should import a valid hotel" do
    hotel_json = {
      "Id" => "test_hotel_1",
      "DestinationId" => @destination.id,
      "Name" => "Test Hotel Name",
      "Description" => "A very nice test hotel.",
      "Latitude" => 1.23,
      "Longitude" => 4.56,
      "Address" => "123 Test St",
      "City" => "Test City",
      "Country" => "SG",
      "Facilities" => ["Pool", "WiFi", "BusinessCenter"]
    }

    assert_difference "RawHotel.count", 1 do
      assert_difference "Location.count", 1 do
        assert_difference "Amenity.count", 3 do
          Acme::HotelImporter.import(hotel_json)
        end
      end
    end

    raw_hotel = RawHotel.find_by(hotel_code: "test_hotel_1", source: "Acme")
    assert_not_nil raw_hotel
    assert_equal "Test Hotel Name", raw_hotel.name
    assert_equal "A very nice test hotel.", raw_hotel.description
    assert_equal @destination, raw_hotel.destination
    assert_equal hotel_json.except("Id", "DestinationId"), raw_hotel.raw_json.except("Id", "DestinationId") # Check raw_json

    location = raw_hotel.location
    assert_not_nil location
    assert_equal 1.23, location.latitude
    assert_equal 4.56, location.longitude
    assert_equal "123 Test St", location.address
    assert_equal "Test City", location.city
    assert_equal "Singapore", location.country

    amenities = raw_hotel.amenities.order(:name)
    assert_equal 3, amenities.count
    assert_equal "business center", amenities[0].name
    assert_equal "outdoor pool", amenities[1].name
    assert_equal "wifi", amenities[2].name
  end

  test "should handle empty, null, and missing text fields" do
    hotel_json = {
      "Id" => "test_hotel_2",
      "DestinationId" => @destination.id,
      "Name" => " ", # Empty string
      "Description" => nil, # Null
      # Address, City, Country are missing
      "Latitude" => 1.23,
      "Longitude" => 4.56,
      "Facilities" => []
    }

    Acme::HotelImporter.import(hotel_json)

    raw_hotel = RawHotel.find_by(hotel_code: "test_hotel_2", source: "Acme")
    assert_not_nil raw_hotel
    assert_equal "", raw_hotel.name # Stripped empty string
    assert_equal "", raw_hotel.description # Nil should become empty string

    location = raw_hotel.location
    assert_not_nil location
    assert_equal "", location.address # Missing should become empty string
    assert_equal "", location.city # Missing should become empty string
    assert_equal "", location.country # Missing should become empty string
  end

  test "should handle dirty text fields" do
    hotel_json = {
      "Id" => "test_hotel_3",
      "DestinationId" => @destination.id,
      "Name" => "  TEST HOTEL NAME  ",
      "Description" => " A VERY NICE TEST HOTEL. ",
      "Address" => " 123 TEST ST ",
      "City" => " TEST CITY ",
      "Country" => " usA ",
      "Latitude" => 1.23,
      "Longitude" => 4.56,
      "Facilities" => []
    }

    Acme::HotelImporter.import(hotel_json)

    raw_hotel = RawHotel.find_by(hotel_code: "test_hotel_3", source: "Acme")
    assert_not_nil raw_hotel
    assert_equal "TEST HOTEL NAME", raw_hotel.name
    assert_equal "A VERY NICE TEST HOTEL.", raw_hotel.description

    location = raw_hotel.location
    assert_not_nil location
    assert_equal "123 TEST ST", location.address
    assert_equal "TEST CITY", location.city
    assert_equal "USA", location.country
  end

  test "should handle unmappable amenities" do
    hotel_json = {
      "Id" => "test_hotel_4",
      "DestinationId" => @destination.id,
      "Name" => "Hotel with bad amenity",
      "Facilities" => ["Pool", "NonExistentAmenity", "WiFi"]
    }

    # Capture logger output
    log_output = StringIO.new
    original_logger = Rails.logger
    Rails.logger = Logger.new(log_output)

    begin
      Acme::HotelImporter.import(hotel_json)
    ensure
      Rails.logger = original_logger # Restore original logger
    end

    raw_hotel = RawHotel.find_by(hotel_code: "test_hotel_4", source: "Acme")
    assert_not_nil raw_hotel

    amenities = raw_hotel.amenities.order(:name)
    assert_equal 2, amenities.count # Only Pool and WiFi should be imported
    assert_equal "outdoor pool", amenities[0].name
    assert_equal "wifi", amenities[1].name

    assert_includes log_output.string, "No mapping found for amenity: NonExistentAmenity"
  end

  test "should update existing hotel and its associations" do
    # Create initial hotel
    initial_hotel_json = {
      "Id" => "test_hotel_update",
      "DestinationId" => @destination.id,
      "Name" => "Old Name",
      "Description" => "Old Description",
      "Latitude" => 1.0,
      "Longitude" => 1.0,
      "Address" => "Old Address",
      "City" => "Old City",
      "Country" => "USA",
      "Facilities" => ["Pool", "WiFi"]
    }
    Acme::HotelImporter.import(initial_hotel_json)
    raw_hotel = RawHotel.find_by(hotel_code: "test_hotel_update", source: "Acme")

    # Update hotel
    updated_hotel_json = {
      "Id" => "test_hotel_update",
      "DestinationId" => @destination.id,
      "Name" => "New Name",
      "Description" => "New Description",
      "Latitude" => 2.0,
      "Longitude" => 2.0,
      "Address" => "New Address",
      "City" => "New City",
      "Country" => "CA", # Change country
      "Facilities" => ["BusinessCenter", "WiFi"] # Change amenities
    }

    assert_no_difference "RawHotel.count" do # Should not create new hotel
      assert_no_difference "Location.count" do # Should update existing location
        Acme::HotelImporter.import(updated_hotel_json)
      end
    end

    raw_hotel.reload # Reload to get updated attributes
    assert_equal "New Name", raw_hotel.name
    assert_equal "New Description", raw_hotel.description

    location = raw_hotel.location
    assert_equal 2.0, location.latitude
    assert_equal 2.0, location.longitude
    assert_equal "New Address", location.address
    assert_equal "New City", location.city
    assert_equal "Canada", location.country

    amenities = raw_hotel.amenities.order(:name)
    assert_equal 2, amenities.count
    assert_equal "business center", amenities[0].name
    assert_equal "wifi", amenities[1].name
  end

  test "should handle nil latitude and longitude" do
    hotel_json = {
      "Id" => "test_hotel_5",
      "DestinationId" => @destination.id,
      "Name" => "Hotel with nil lat/lng",
      "Latitude" => nil,
      "Longitude" => nil,
      "Address" => "123 Test St",
      "City" => "Test City",
      "Country" => "USA",
      "Facilities" => []
    }

    Acme::HotelImporter.import(hotel_json)

    raw_hotel = RawHotel.find_by(hotel_code: "test_hotel_5", source: "Acme")
    assert_not_nil raw_hotel

    location = raw_hotel.location
    assert_not_nil location
    assert_nil location.latitude
    assert_nil location.longitude
  end
end
