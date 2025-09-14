require "test_helper"

class Merger::ImageMergerTest < ActiveSupport::TestCase
  setup do
    @hotel = hotels(:one)
    @raw_hotel_1 = raw_hotels(:one)
    @raw_hotel_2 = raw_hotels(:two)
    @raw_hotel_3 = raw_hotels(:three)

    # Clear existing images for the hotel and raw hotels to ensure a clean slate for each test
    @hotel.images.delete_all
    @raw_hotel_1.images.delete_all
    @raw_hotel_2.images.delete_all
    @raw_hotel_3.images.delete_all
  end

  test "should merge images correctly with deduplication and max category/description" do
    # Images for raw_hotel_1
    Image.create!(owner: @raw_hotel_1, url: "url1.jpg", category: "rooms", description: "Room view")
    Image.create!(owner: @raw_hotel_1, url: "url2.jpg", category: "amenities", description: "Pool area")

    # Images for raw_hotel_2 (duplicate url1, new url3)
    Image.create!(owner: @raw_hotel_2, url: "url1.jpg", category: "suite", description: "Suite view") # Max category/description should be picked
    Image.create!(owner: @raw_hotel_2, url: "url3.jpg", category: "dining", description: "Restaurant")

    # Images for raw_hotel_3 (duplicate url2, new url4)
    Image.create!(owner: @raw_hotel_3, url: "url2.jpg", category: "spa", description: "Spa area") # Max category/description should be picked
    Image.create!(owner: @raw_hotel_3, url: "url4.jpg", category: "exterior", description: "Building")

    Merger::ImageMerger.merge(@hotel, [@raw_hotel_1, @raw_hotel_2, @raw_hotel_3])
    @hotel.reload

    assert_equal 4, @hotel.images.count

    image1 = @hotel.images.find_by(url: "url1.jpg")
    assert_not_nil image1
    assert_equal "suite", image1.category # 'suite' > 'rooms'
    assert_equal "Suite view", image1.description # 'Suite view' > 'Room view'

    image2 = @hotel.images.find_by(url: "url2.jpg")
    assert_not_nil image2
    assert_equal "spa", image2.category # 'spa' > 'amenities'
    assert_equal "Spa area", image2.description # 'Spa area' > 'Pool area'

    image3 = @hotel.images.find_by(url: "url3.jpg")
    assert_not_nil image3
    assert_equal "dining", image3.category
    assert_equal "Restaurant", image3.description

    image4 = @hotel.images.find_by(url: "url4.jpg")
    assert_not_nil image4
    assert_equal "exterior", image4.category
    assert_equal "Building", image4.description
  end

  test "should handle empty image arrays from raw hotels" do
    # Raw hotels have no images
    Merger::ImageMerger.merge(@hotel, [@raw_hotel_1, @raw_hotel_2, @raw_hotel_3])
    @hotel.reload

    assert_empty @hotel.images
  end

  test "should handle images with nil URLs, categories, or descriptions" do
    Image.create!(owner: @raw_hotel_1, url: "url5.jpg", category: nil, description: "Description 5")
    Image.create!(owner: @raw_hotel_2, url: "url6.jpg", category: "Category 6", description: nil)
    Image.create!(owner: @raw_hotel_3, url: nil, category: "Category 7", description: "Description 7") # Should not be merged

    Merger::ImageMerger.merge(@hotel, [@raw_hotel_1, @raw_hotel_2, @raw_hotel_3])
    @hotel.reload

    assert_equal 2, @hotel.images.count

    image5 = @hotel.images.find_by(url: "url5.jpg")
    assert_not_nil image5
    assert_nil image5.category
    assert_equal "Description 5", image5.description

    image6 = @hotel.images.find_by(url: "url6.jpg")
    assert_not_nil image6
    assert_equal "Category 6", image6.category
    assert_nil image6.description
  end

  test "should deduplicate images based on URL and pick max category/description" do
    Image.create!(owner: @raw_hotel_1, url: "dedup_url.jpg", category: "A", description: "Desc A")
    Image.create!(owner: @raw_hotel_2, url: "dedup_url.jpg", category: "C", description: "Desc C")
    Image.create!(owner: @raw_hotel_3, url: "dedup_url.jpg", category: "B", description: "Desc B")

    Merger::ImageMerger.merge(@hotel, [@raw_hotel_1, @raw_hotel_2, @raw_hotel_3])
    @hotel.reload

    assert_equal 1, @hotel.images.count
    deduped_image = @hotel.images.first
    assert_equal "dedup_url.jpg", deduped_image.url
    assert_equal "C", deduped_image.category # 'C' is max
    assert_equal "Desc C", deduped_image.description # 'Desc C' is max
  end
end
