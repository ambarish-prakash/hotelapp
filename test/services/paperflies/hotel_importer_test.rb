require "test_helper"

class Paperflies::HotelImporterTest < ActiveSupport::TestCase
  setup do
    @destination = destinations(:one)
    # Stub the validate_image_url method to prevent actual network requests
    BaseImporter.stubs(:validate_image_url).returns(true)
  end

  test "should import a valid hotel" do
    hotel_json = {
      "hotel_id" => "paperflies_hotel_1",
      "destination_id" => @destination.id,
      "hotel_name" => "Paperflies Test Hotel Name",
      "location" => {"address" => "123 Paperflies St", "country" => "Japan"},
      "details" => "A very nice paperflies test hotel.",
      "amenities" => {"general" => ["indoor pool", "business center"], "room" => ["tv"]},
      "images" => {
        "rooms" => [
          {"link" => "http://paperflies.com/room1.jpg", "caption" => "Room one"}
        ],
        "site" => [
          {"link" => "http://paperflies.com/site1.jpg", "caption" => "Site one"}
        ]
      },
      "booking_conditions" => ["Condition 1", "Condition 2"]
    }

    assert_difference "RawHotel.count", 1 do
      assert_difference "Location.count", 1 do
        assert_difference "Amenity.count", 3 do
          assert_difference "Image.count", 2 do
            Paperflies::HotelImporter.import(hotel_json)
          end
        end
      end
    end

    raw_hotel = RawHotel.find_by(hotel_code: "paperflies_hotel_1", source: "Paperflies")
    assert_not_nil raw_hotel
    assert_equal "Paperflies Test Hotel Name", raw_hotel.name
    assert_equal "A very nice paperflies test hotel.", raw_hotel.description
    assert_equal @destination, raw_hotel.destination
    assert_equal ["Condition 1", "Condition 2"], raw_hotel.booking_conditions

    location = raw_hotel.location
    assert_not_nil location
    assert_nil location.latitude
    assert_nil location.longitude
    assert_equal "123 Paperflies St", location.address
    assert_equal "", location.city
    assert_equal "Japan", location.country

    amenities = raw_hotel.amenities.order(:name)
    assert_equal 3, amenities.count
    assert_equal "business center", amenities[0].name
    assert_equal "indoor pool", amenities[1].name
    assert_equal "tv", amenities[2].name

    images = raw_hotel.images.order(:url)
    assert_equal 2, images.count
    assert_equal "http://paperflies.com/room1.jpg", images[0].url
    assert_equal "Room one", images[0].description
    assert_equal "rooms", images[0].category
    assert_equal "http://paperflies.com/site1.jpg", images[1].url
    assert_equal "Site one", images[1].description
    assert_equal "site", images[1].category
  end

  test "should handle empty, null, and missing text fields" do
    hotel_json = {
      "hotel_id" => "paperflies_hotel_2",
      "destination_id" => @destination.id,
      "hotel_name" => " ", # Empty string
      "details" => nil, # Null
      "location" => {"address" => " ", "country" => nil}, # Empty/Null
      "amenities" => {"general" => [], "room" => []},
      "images" => {},
      "booking_conditions" => nil
    }

    Paperflies::HotelImporter.import(hotel_json)

    raw_hotel = RawHotel.find_by(hotel_code: "paperflies_hotel_2", source: "Paperflies")
    assert_not_nil raw_hotel
    assert_equal "", raw_hotel.name # Stripped empty string
    assert_equal "", raw_hotel.description # Nil becomes empty string
    assert_equal [], raw_hotel.booking_conditions # Nil becomes empty array

    location = raw_hotel.location
    assert_not_nil location
    assert_equal "", location.address
    assert_equal "", location.country # Nil becomes empty string
  end

  test "should handle dirty text fields" do
    hotel_json = {
      "hotel_id" => "paperflies_hotel_3",
      "destination_id" => @destination.id,
      "hotel_name" => "  PAPERFLIES TEST HOTEL NAME  ",
      "details" => " A VERY NICE PAPERFLIES TEST HOTEL. ",
      "location" => {"address" => " 123 PAPERFLIES ST ", "country" => " JAPAN "},
      "amenities" => {"general" => [], "room" => []},
      "images" => {},
      "booking_conditions" => [" Condition 1 ", " Condition 2 "]
    }

    Paperflies::HotelImporter.import(hotel_json)

    raw_hotel = RawHotel.find_by(hotel_code: "paperflies_hotel_3", source: "Paperflies")
    assert_not_nil raw_hotel
    assert_equal "PAPERFLIES TEST HOTEL NAME", raw_hotel.name
    assert_equal "A VERY NICE PAPERFLIES TEST HOTEL.", raw_hotel.description
    assert_equal ["Condition 1", "Condition 2"], raw_hotel.booking_conditions # booking_conditions are now stripped

    location = raw_hotel.location
    assert_not_nil location
    assert_equal "123 PAPERFLIES ST", location.address
    assert_equal "JAPAN", location.country
  end

  test "should handle unmappable amenities" do
    hotel_json = {
      "hotel_id" => "paperflies_hotel_4",
      "destination_id" => @destination.id,
      "hotel_name" => "Hotel with bad amenity",
      "amenities" => {"general" => ["indoor pool", "NonExistentAmenity"], "room" => ["tv"]}
    }

    # Capture logger output
    log_output = StringIO.new
    original_logger = Rails.logger
    Rails.logger = Logger.new(log_output)

    begin
      Paperflies::HotelImporter.import(hotel_json)
    ensure
      Rails.logger = original_logger # Restore original logger
    end

    raw_hotel = RawHotel.find_by(hotel_code: "paperflies_hotel_4", source: "Paperflies")
    assert_not_nil raw_hotel

    amenities = raw_hotel.amenities.order(:name)
    assert_equal 2, amenities.count # Only indoor pool and tv should be imported
    assert_equal "indoor pool", amenities[0].name
    assert_equal "tv", amenities[1].name

    assert_includes log_output.string, "No mapping found for amenity: NonExistentAmenity"
  end

  test "should update existing hotel and its associations" do
    # Create initial hotel
    initial_hotel_json = {
      "hotel_id" => "paperflies_hotel_update",
      "destination_id" => @destination.id,
      "hotel_name" => "Old Name",
      "details" => "Old Description",
      "location" => {"address" => "Old Address", "country" => "USA"},
      "amenities" => {"general" => ["indoor pool"], "room" => ["tv"]},
      "images" => {
        "rooms" => [
          {"link" => "http://paperflies.com/old_room.jpg", "caption" => "Old Room"}
        ]
      },
      "booking_conditions" => ["Old Condition"]
    }
    Paperflies::HotelImporter.import(initial_hotel_json)
    raw_hotel = RawHotel.find_by(hotel_code: "paperflies_hotel_update", source: "Paperflies")

    # Update hotel
    updated_hotel_json = {
      "hotel_id" => "paperflies_hotel_update",
      "destination_id" => @destination.id,
      "hotel_name" => "New Name",
      "details" => "New Description",
      "location" => {"address" => "New Address", "country" => "CAN"},
      "amenities" => {"general" => ["business center"], "room" => ["tv"]}, # Change amenities
      "images" => {
        "site" => [
          {"link" => "http://paperflies.com/new_site.jpg", "caption" => "New Site"}
        ]
      },
      "booking_conditions" => ["New Condition"]
    }

    assert_no_difference "RawHotel.count" do # Should not create new hotel
      assert_no_difference "Location.count" do # Should update existing location
        Paperflies::HotelImporter.import(updated_hotel_json)
      end
    end

    raw_hotel.reload # Reload to get updated attributes
    assert_equal "New Name", raw_hotel.name
    assert_equal "New Description", raw_hotel.description
    assert_equal ["New Condition"], raw_hotel.booking_conditions

    location = raw_hotel.location
    assert_equal "New Address", location.address
    assert_equal "CAN", location.country

    amenities = raw_hotel.amenities.order(:name)
    assert_equal 2, amenities.count
    assert_equal "business center", amenities[0].name
    assert_equal "tv", amenities[1].name

    images = raw_hotel.images.order(:url)
    assert_equal 1, images.count
    assert_equal "http://paperflies.com/new_site.jpg", images[0].url
    assert_equal "New Site", images[0].description
    assert_equal "site", images[0].category
  end

  test "should handle nil latitude and longitude" do
    hotel_json = {
      "hotel_id" => "paperflies_hotel_5",
      "destination_id" => @destination.id,
      "hotel_name" => "Hotel with nil lat/lng",
      "location" => {"address" => "123 Paperflies St", "country" => "Japan", "latitude" => nil, "longitude" => nil},
      "amenities" => {"general" => [], "room" => []},
      "images" => {},
      "booking_conditions" => []
    }

    Paperflies::HotelImporter.import(hotel_json)

    raw_hotel = RawHotel.find_by(hotel_code: "paperflies_hotel_5", source: "Paperflies")
    assert_not_nil raw_hotel

    location = raw_hotel.location
    assert_not_nil location
    assert_nil location.latitude
    assert_nil location.longitude
  end

  test "should handle invalid image urls" do
    hotel_json = {
      "hotel_id" => "paperflies_hotel_5",
      "destination_id" => @destination.id,
      "hotel_name" => "Hotel with invalid image",
      "images" => {
        "site" => [
          {"link" => "http://paperflies.com/new_site.jpg", "caption" => "New Site"}
        ]
      },
    }

    BaseImporter.stubs(:validate_image_url).returns(false)

    Paperflies::HotelImporter.import(hotel_json)

    raw_hotel = RawHotel.find_by(hotel_code: "paperflies_hotel_5", source: "Paperflies")
    assert_not_nil raw_hotel

    assert_equal 0, raw_hotel.images.count
  end
end
