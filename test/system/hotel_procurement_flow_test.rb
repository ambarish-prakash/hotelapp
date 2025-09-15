# frozen_string_literal: true

require "application_system_test_case"
require "sidekiq/testing"

class HotelProcurementFlowTest < ApplicationSystemTestCase
  setup do
    Sidekiq::Testing.inline! # Switch to inline mode for this test
  end

  teardown do
    Sidekiq::Testing.fake! # Return to fake mode after the test
  end

  test "full asynchronous procurement and merge flow" do
    source = "acme"
    hotel_code = "test_hotel_system"
    destination = destinations(:one)

    # 1. Mock the external endpoint
    sample_hotel_data = {
      "Id" => hotel_code,
      "DestinationId" => destination.id,
      "Name" => "System Test Hotel",
      "Description" => "A hotel created by a system test.",
      "Latitude" => 10.0,
      "Longitude" => 20.0,
      "Address" => "123 System Test St",
      "City" => "Testville",
      "Country" => "USA",
      "Facilities" => ["Pool", "WiFi"]
    }

    # Ensure we start clean
    RawHotel.where(hotel_code: hotel_code, source: source).destroy_all
    Hotel.where(hotel_code: hotel_code).destroy_all

    # Mock the fetcher to return our sample data
    Procurement::Fetcher.expects(:call).returns([sample_hotel_data])

    # 2. Trigger the procurement job
    assert_difference("RawHotel.count", 1) do
      HotelProcurementJob.perform_later(source)
    end

    # 3. Verify the outcome
    # Because of inline testing, the procurement and merge jobs have already run.
    hotel = Hotel.find_by(hotel_code: hotel_code)
    assert_not_nil hotel, "A Hotel record should have been created"

    # Verify that the data was merged correctly
    assert_equal "System Test Hotel", hotel.name
    assert_equal "A hotel created by a system test.", hotel.description
    assert_equal 10.0, hotel.location.latitude
    assert_equal 2, hotel.amenities.count
  end
end
