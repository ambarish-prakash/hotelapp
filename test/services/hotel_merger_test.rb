require "test_helper"

class HotelMergerTest < ActiveSupport::TestCase
  test "merge logs a message" do
    hotel_code = "some_hotel_code"
    Rails.logger.expects(:info).with("Merging hotel data for hotel code: #{hotel_code}").once
    HotelMerger.merge(hotel_code)
  end
end
