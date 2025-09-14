require "test_helper"
require "minitest/mock"

class HotelMergeJobTest < ActiveJob::TestCase
  setup do
    @old_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test   # <- prevent Sidekiq client/Redis connect
  end

  teardown do
    ActiveJob::Base.queue_adapter = @old_adapter
  end

  test "performs merge with hotel code" do
    hotel_code = "some_hotel_code"

    merger_mock = Minitest::Mock.new
    merger_mock.expect(:call, nil, [hotel_code])

    logger_mock = Minitest::Mock.new
    logger_mock.expect(:info, nil, [Regexp.new("Starting merge")])
    logger_mock.expect(:info, nil, [Regexp.new("Completed merge")])

    Merger::HotelMerger.stub :merge, merger_mock do
      Rails.stub :logger, logger_mock do
        HotelMergeJob.perform_now(hotel_code)
      end
    end

    assert merger_mock.verify
    assert logger_mock.verify
  end

  test "logs errors from HotelMerger.merge but does not bubble with retry_on" do
    hotel_code = "failing_code"

    logger_mock = Minitest::Mock.new
    logger_mock.expect(:info, nil, [Regexp.new("Starting merge")])
    logger_mock.expect(:error, nil, [Regexp.new("Failed to merge hotel data for hotel code: #{hotel_code}. Error: boom")])
    logger_mock.expect(:error, nil, [String]) # backtrace

    Merger::HotelMerger.stub :merge, ->(_code) { raise StandardError, "boom" } do
      Rails.stub :logger, logger_mock do
        # no assert_raises — swallowed by retry_on,
        # and now re-enqueued into the TestAdapter (no Sidekiq/Redis touch)
        HotelMergeJob.perform_now(hotel_code)
      end
    end

    assert logger_mock.verify
  end
end
