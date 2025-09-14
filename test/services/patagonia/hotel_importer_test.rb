require "test_helper"

class Patagonia::HotelImporterTest < ActiveSupport::TestCase
  setup do
    @destination = destinations(:one)
  end

  test "should import a valid hotel" do
    hotel_json = {
      "id" => "patagonia_hotel_1",
      "destination" => @destination.id,
      "name" => "Patagonia Test Hotel Name",
      "info" => "A very nice patagonia test hotel.",
      "lat" => 1.23,
      "lng" => 4.56,
      "address" => "123 Patagonia St",
      "amenities" => ["Aircon", "Tv", "Coffee machine"],
      "images" => {
        "rooms" => [
          {"url" => "http://patagonia.com/room1.jpg", "description" => "Room one"}
        ],
        "amenities" => [
          {"url" => "http://patagonia.com/amenity1.jpg", "description" => "Amenity one"}
        ]
      }
    }

    assert_difference "RawHotel.count", 1 do
      assert_difference "Location.count", 1 do
        assert_difference "Amenity.count", 3 do
          assert_difference "Image.count", 2 do
            Patagonia::HotelImporter.import(hotel_json)
          end
        end
      end
    end

    raw_hotel = RawHotel.find_by(hotel_code: "patagonia_hotel_1", source: "Patagonia")
    assert_not_nil raw_hotel
    assert_equal "Patagonia Test Hotel Name", raw_hotel.name
    assert_equal "A very nice patagonia test hotel.", raw_hotel.description
    assert_equal @destination, raw_hotel.destination

    location = raw_hotel.location
    assert_not_nil location
    assert_equal 1.23, location.latitude
    assert_equal 4.56, location.longitude
    assert_equal "123 Patagonia St", location.address
    assert_equal "", location.city
    assert_equal "", location.country

    amenities = raw_hotel.amenities.order(:name)
    assert_equal 3, amenities.count
    assert_equal "aircon", amenities[0].name
    assert_equal "coffee machine", amenities[1].name
    assert_equal "tv", amenities[2].name

    images = raw_hotel.images.order(:url)
    assert_equal 2, images.count
    assert_equal "http://patagonia.com/amenity1.jpg", images[0].url
    assert_equal "Amenity one", images[0].description
    assert_equal "amenities", images[0].category
    assert_equal "http://patagonia.com/room1.jpg", images[1].url
    assert_equal "Room one", images[1].description
    assert_equal "rooms", images[1].category
  end

  test "should handle empty, null, and missing text fields" do
    hotel_json = {
      "id" => "patagonia_hotel_2",
      "destination" => @destination.id,
      "name" => " ", # Empty string
      "info" => nil, # Null
      # address is missing
      "lat" => 1.23,
      "lng" => 4.56,
      "amenities" => [],
      "images" => {}
    }

    Patagonia::HotelImporter.import(hotel_json)

    raw_hotel = RawHotel.find_by(hotel_code: "patagonia_hotel_2", source: "Patagonia")
    assert_not_nil raw_hotel
    assert_equal "", raw_hotel.name # Stripped empty string
    assert_equal "", raw_hotel.description # Nil should become empty string

    location = raw_hotel.location
    assert_not_nil location
    assert_equal "", location.address # Missing should become empty string
  end

  test "should handle dirty text fields" do
    hotel_json = {
      "id" => "patagonia_hotel_3",
      "destination" => @destination.id,
      "name" => "  PATAGONIA TEST HOTEL NAME  ",
      "info" => " A VERY NICE PATAGONIA TEST HOTEL. ",
      "address" => " 123 PATAGONIA ST ",
      "lat" => 1.23,
      "lng" => 4.56,
      "amenities" => [],
      "images" => {}
    }

    Patagonia::HotelImporter.import(hotel_json)

    raw_hotel = RawHotel.find_by(hotel_code: "patagonia_hotel_3", source: "Patagonia")
    assert_not_nil raw_hotel
    assert_equal "PATAGONIA TEST HOTEL NAME", raw_hotel.name
    assert_equal "A VERY NICE PATAGONIA TEST HOTEL.", raw_hotel.description

    location = raw_hotel.location
    assert_not_nil location
    assert_equal "123 PATAGONIA ST", location.address
  end

  test "should handle unmappable amenities" do
    hotel_json = {
      "id" => "patagonia_hotel_4",
      "destination" => @destination.id,
      "name" => "Hotel with bad amenity",
      "amenities" => ["Aircon", "NonExistentAmenity", "Tv"]
    }

    # Capture logger output
    log_output = StringIO.new
    original_logger = Rails.logger
    Rails.logger = Logger.new(log_output)

    begin
      Patagonia::HotelImporter.import(hotel_json)
    ensure
      Rails.logger = original_logger # Restore original logger
    end

    raw_hotel = RawHotel.find_by(hotel_code: "patagonia_hotel_4", source: "Patagonia")
    assert_not_nil raw_hotel

    amenities = raw_hotel.amenities.order(:name)
    assert_equal 2, amenities.count # Only Aircon and Tv should be imported
    assert_equal "aircon", amenities[0].name
    assert_equal "tv", amenities[1].name

    assert_includes log_output.string, "No mapping found for amenity: NonExistentAmenity"
  end

  test "should update existing hotel and its associations" do
    # Create initial hotel
    initial_hotel_json = {
      "id" => "patagonia_hotel_update",
      "destination" => @destination.id,
      "name" => "Old Name",
      "info" => "Old Description",
      "lat" => 1.0,
      "lng" => 1.0,
      "address" => "Old Address",
      "amenities" => ["Aircon", "Tv"],
      "images" => {
        "rooms" => [
          {"url" => "http://patagonia.com/old_room.jpg", "description" => "Old Room"}
        ]
      }
    }
    Patagonia::HotelImporter.import(initial_hotel_json)
    raw_hotel = RawHotel.find_by(hotel_code: "patagonia_hotel_update", source: "Patagonia")

    # Update hotel
    updated_hotel_json = {
      "id" => "patagonia_hotel_update",
      "destination" => @destination.id,
      "name" => "New Name",
      "info" => "New Description",
      "lat" => 2.0,
      "lng" => 2.0,
      "address" => "New Address",
      "amenities" => ["Coffee machine", "Tv"], # Change amenities
      "images" => {
        "amenities" => [
          {"url" => "http://patagonia.com/new_amenity.jpg", "description" => "New Amenity"}
        ]
      }
    }

    assert_no_difference "RawHotel.count" do # Should not create new hotel
      assert_no_difference "Location.count" do # Should update existing location
        Patagonia::HotelImporter.import(updated_hotel_json)
      end
    end

    raw_hotel.reload # Reload to get updated attributes
    assert_equal "New Name", raw_hotel.name
    assert_equal "New Description", raw_hotel.description

    location = raw_hotel.location
    assert_equal 2.0, location.latitude
    assert_equal 2.0, location.longitude
    assert_equal "New Address", location.address

    amenities = raw_hotel.amenities.order(:name)
    assert_equal 2, amenities.count
    assert_equal "coffee machine", amenities[0].name
    assert_equal "tv", amenities[1].name

    images = raw_hotel.images.order(:url)
    assert_equal 1, images.count
    assert_equal "http://patagonia.com/new_amenity.jpg", images[0].url
    assert_equal "New Amenity", images[0].description
    assert_equal "amenities", images[0].category
  end

  test "should handle nil latitude and longitude" do
    hotel_json = {
      "id" => "patagonia_hotel_5",
      "destination" => @destination.id,
      "name" => "Hotel with nil lat/lng",
      "lat" => nil,
      "lng" => nil,
      "address" => "123 Patagonia St",
      "amenities" => [],
      "images" => {}
    }

    Patagonia::HotelImporter.import(hotel_json)

    raw_hotel = RawHotel.find_by(hotel_code: "patagonia_hotel_5", source: "Patagonia")
    assert_not_nil raw_hotel

    location = raw_hotel.location
    assert_not_nil location
    assert_nil location.latitude
    assert_nil location.longitude
  end
end
