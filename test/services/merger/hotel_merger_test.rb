require "test_helper"
require "minitest/mock"

class Merger::HotelMergerTest < ActiveSupport::TestCase
  setup do
    @hotel_code = "TESTCODE"
    @destination = destinations(:one)

    @raw_hotel_1 = RawHotel.create!(hotel_code: @hotel_code, name: "Test Hotel 1", destination: @destination, source: "Acme")
    @raw_hotel_1.create_location! unless @raw_hotel_1.location.present?

    @raw_hotel_2 = RawHotel.create!(hotel_code: @hotel_code, name: "Test Hotel 2", destination: @destination, source: "Paperflies")
    @raw_hotel_2.create_location! unless @raw_hotel_2.location.present?
  end

  teardown do
    RawHotel.where(hotel_code: @hotel_code).destroy_all
    Hotel.where(hotel_code: @hotel_code).destroy_all
  end

  test "should call all sub-mergers" do
    expected_raw_hotels = [@raw_hotel_1, @raw_hotel_2].sort_by(&:id)

    make_mock = -> {
      mock = Minitest::Mock.new
      mock.expect(:call, nil) do |hotel, raw_hotels|
        hotel.is_a?(Hotel) &&
          raw_hotels.sort_by(&:id) == expected_raw_hotels
      end
      mock
    }

    description_merger_mock     = make_mock.call
    booking_condition_merger_mock = make_mock.call
    location_merger_mock        = make_mock.call
    amenities_merger_mock       = make_mock.call
    image_merger_mock           = make_mock.call

    Merger::DescriptionMerger.stub :merge, description_merger_mock do
      Merger::BookingConditionMerger.stub :merge, booking_condition_merger_mock do
        Merger::LocationMerger.stub :merge, location_merger_mock do
          Merger::AmenitiesMerger.stub :merge, amenities_merger_mock do
            Merger::ImageMerger.stub :merge, image_merger_mock do
              Merger::HotelMerger.merge(@hotel_code)
            end
          end
        end
      end
    end

    # Explicit assertions so Minitest counts them
    assert description_merger_mock.verify
    assert booking_condition_merger_mock.verify
    assert location_merger_mock.verify
    assert amenities_merger_mock.verify
    assert image_merger_mock.verify
  end

  test "should create a new hotel if one does not exist" do
    assert_nil Hotel.find_by(hotel_code: @hotel_code)

    Merger::HotelMerger.merge(@hotel_code)

    hotel = Hotel.find_by(hotel_code: @hotel_code)
    assert_not_nil hotel
    assert_equal @hotel_code, hotel.hotel_code
    assert_equal @raw_hotel_1.name, hotel.name
    assert_equal @raw_hotel_1.destination, hotel.destination
  end

  test "should update an existing hotel if one exists" do
    existing_hotel = Hotel.create!(hotel_code: @hotel_code, name: "Old Name", destination: destinations(:two))

    @raw_hotel_1.update!(name: "Updated Name", destination: @destination)
    @raw_hotel_2.update!(name: "Updated Name", destination: @destination)

    Merger::HotelMerger.merge(@hotel_code)

    updated_hotel = Hotel.find(existing_hotel.id)
    assert_equal "Updated Name", updated_hotel.name
    assert_equal @destination, updated_hotel.destination
  end

  test "should delete existing hotel if raw_hotels are empty" do
    # Create an existing hotel
    existing_hotel = Hotel.create!(hotel_code: @hotel_code, name: "Hotel to be deleted", destination: @destination)
    assert_not_nil Hotel.find_by(hotel_code: @hotel_code)

    # Delete all raw hotels so that raw_hotels becomes empty
    RawHotel.where(hotel_code: @hotel_code).destroy_all
    assert_empty RawHotel.where(hotel_code: @hotel_code)

    Merger::HotelMerger.merge(@hotel_code)

    # Assert that the existing hotel has been deleted
    assert_nil Hotel.find_by(hotel_code: @hotel_code)
  end

  test "should return without action if raw_hotels are empty and no hotel exists" do
    # Ensure no hotel exists
    Hotel.where(hotel_code: @hotel_code).destroy_all
    assert_nil Hotel.find_by(hotel_code: @hotel_code)

    # Delete all raw hotels so that raw_hotels becomes empty
    RawHotel.where(hotel_code: @hotel_code).destroy_all
    assert_empty RawHotel.where(hotel_code: @hotel_code)

    # Call merge and assert that no hotel is created
    Merger::HotelMerger.merge(@hotel_code)

    assert_nil Hotel.find_by(hotel_code: @hotel_code)
  end
end
