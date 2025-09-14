require "test_helper"

class ImageTest < ActiveSupport::TestCase
  test "should be valid with all attributes" do
    raw_hotel = raw_hotels(:one)
    image = Image.new(
      owner: raw_hotel,
      category: "rooms",
      url: "http://example.com/image.jpg",
      description: "A nice room"
    )
    assert image.valid?
  end

  test "should not allow duplicate url for the same owner" do
    raw_hotel = raw_hotels(:one)
    Image.create!(
      owner: raw_hotel,
      category: "rooms",
      url: "http://example.com/image.jpg"
    )

    duplicate_image = Image.new(
      owner: raw_hotel,
      category: "site", # Category can be different
      url: "http://example.com/image.jpg"
    )

    assert_raises(ActiveRecord::RecordNotUnique) do
      duplicate_image.save(validate: false)
    end
  end

  test "should allow same url for different owners" do
    raw_hotel_one = raw_hotels(:one)
    raw_hotel_two = raw_hotels(:two)

    Image.create!(
      owner: raw_hotel_one,
      url: "http://example.com/image.jpg"
    )

    other_image = Image.new(
      owner: raw_hotel_two,
      url: "http://example.com/image.jpg"
    )

    assert other_image.valid?
  end

  test "should not be valid without an owner" do
    image = Image.new(
      category: "rooms",
      url: "http://example.com/image.jpg"
    )
    assert_not image.valid?
  end
end
