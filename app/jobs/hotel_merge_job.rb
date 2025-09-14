class HotelMergeJob < ApplicationJob
  queue_as :merge

  retry_on(StandardError, attempts: 3)

  def perform(hotel_code)
    Rails.logger.info("[HotelMergeJob] Starting merge of hotel data for hotel code: #{hotel_code}")
    begin
      Merger::HotelMerger.merge(hotel_code)
      Rails.logger.info("[HotelMergeJob] Completed merge of hotel data for hotel code: #{hotel_code}")
    rescue => e
      Rails.logger.error("[HotelMergeJob] Failed to merge hotel data for hotel code: #{hotel_code}. Error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      raise # Re-raise the exception to allow retry_on to catch it
    end
  end
end
