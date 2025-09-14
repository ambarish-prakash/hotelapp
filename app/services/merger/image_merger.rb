# frozen_string_literal: true

module Merger
  class ImageMerger
    # Merges images for the hotel.
    # It deduplicates images by URL and selects the MAX category and description.
    # @param hotel [Hotel] The hotel record to update.
    # @param raw_hotels [Array<RawHotel>] The raw hotel records.
    def self.merge(hotel, raw_hotels)
      hotel.images.delete_all

      # Find deduped images from raw hotels and set them
      # Using max from category and description to get non empty strings
      deduped_images = Image.where(owner: raw_hotels)
                            .group(:url)
                            .select(
                              :url,
                              "MAX(category) AS category",
                              "MAX(description) AS description"
                            )

      if deduped_images.any?
        now = Time.current
        records_to_insert = deduped_images.map do |image|
          {
            url: image.url,
            category: image.category,
            description: image.description,
            owner_id: hotel.id,
            owner_type: 'Hotel',
            created_at: now,
            updated_at: now
          }
        end
        Image.insert_all(records_to_insert)
      end
    end
  end
end