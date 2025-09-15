require "test_helper"

class HotelsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @destination = destinations(:one)
    @destination_two = destinations(:two)
    @hotel = hotels(:one)
    @hotel_two = hotels(:two)
    @hotel_three = hotels(:three)
  end

  test "should get index as html" do
    get hotels_url
    assert_response :success
    assert_select "h1", "Hotels"
  end

  test "should get index as json" do
    get hotels_url, as: :json
    assert_response :success
    parsed_response = JSON.parse(response.body)
    assert_equal Hotel.all.count, parsed_response.count
    Hotel.all.each_with_index do |hotel, i|
      assert_equal HotelSerializer.new(hotel).as_json.deep_stringify_keys, parsed_response[i]
    end
  end

  test "should get index as html filtered by hotel_codes" do
    get hotels_url, params: { hotel_ids: "#{@hotel.hotel_code},#{@hotel_two.hotel_code}" }
    assert_response :success
    assert_select "h1", "Hotels"
  end

  test "should get index as json filtered by hotel_codes" do
    get hotels_url, params: { hotel_ids: "#{@hotel.hotel_code},#{@hotel_two.hotel_code}" }, as: :json
    assert_response :success
    parsed_response = JSON.parse(response.body)
    assert_equal 2, parsed_response.count
    expected_hotels = [ @hotel, @hotel_two ].sort_by(&:hotel_code)
    parsed_response.sort_by! { |h| h["id"] }
    expected_hotels.each_with_index do |hotel, i|
      assert_equal HotelSerializer.new(hotel).as_json.deep_stringify_keys, parsed_response[i]
    end
  end

  test "should get index as html filtered by destination_id" do
    get hotels_url, params: { destination_id: @destination.id }
    assert_response :success
    assert_select "h1", "Hotels"
  end

  test "should get index as json filtered by destination_id" do
    get hotels_url, params: { destination_id: @destination.id }, as: :json
    assert_response :success
    parsed_response = JSON.parse(response.body)
    expected_hotels = Hotel.where(destination_id: @destination.id).sort_by(&:hotel_code)
    assert_equal expected_hotels.count, parsed_response.count
    parsed_response.sort_by! { |h| h["id"] }
    expected_hotels.each_with_index do |hotel, i|
      assert_equal HotelSerializer.new(hotel).as_json.deep_stringify_keys, parsed_response[i]
    end
  end

  test "should get index as json filtered by hotel_codes and destination_id" do
    get hotels_url, params: { hotel_ids: "#{@hotel.hotel_code}", destination_id: @destination.id }, as: :json
    assert_response :success
    parsed_response = JSON.parse(response.body)
    assert_equal 1, parsed_response.count
    assert_equal HotelSerializer.new(@hotel).as_json.deep_stringify_keys, parsed_response.first
  end

  test "should get index as json filtered by hotel_codes and destination_id with no results" do
    get hotels_url, params: { hotel_ids: "#{@hotel.hotel_code}", destination_id: @destination_two.id }, as: :json
    assert_response :success
    assert_empty JSON.parse(response.body)
  end

  test "should show hotel as html" do
    get hotel_url(@hotel)
    assert_response :success
    assert_select "h1", @hotel.name
  end

  test "should show hotel as json" do
    get hotel_url(@hotel), as: :json
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal HotelSerializer.new(@hotel).as_json.deep_stringify_keys, json_response
  end

  test "should return 404 for non-existent hotel" do
    get hotel_url(99999), as: :json
    assert_response :not_found
  end
end
