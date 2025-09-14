require "test_helper"

class HotelMergeJobTest < ActiveJob::TestCase
  test "performs merge with hotel code" do
    hotel_code = "some_hotel_code"

    sequence = Mocha::Sequence.new('merge_sequence')

    Rails.logger.expects(:info).with("Starting merge of hotel data for hotel code: #{hotel_code}").once.in_sequence(sequence)
    HotelMerger.expects(:merge).with(hotel_code).once.in_sequence(sequence)
    Rails.logger.expects(:info).with("Completed merge of hotel data for hotel code: #{hotel_code}").once.in_sequence(sequence)

    HotelMergeJob.perform_now(hotel_code)
  end
end
