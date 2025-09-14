class HotelSerializer < ActiveModel::Serializer
  attributes :id, :destination_id, :name, :description, :booking_conditions, :amenities, :images

  has_one :location, serializer: LocationSerializer

  def id
    object.hotel_code
  end

  def amenities
    object.amenities.group_by(&:category).transform_values do |amenities_in_category|
      amenities_in_category.map(&:name)
    end
  end

  def images
    object.images.group_by(&:category).transform_values do |images_in_category|
      images_in_category.map do |image|
        { link: image.url, description: image.description }
      end
    end
  end
end
