class LocationSerializer < ActiveModel::Serializer
  attributes :lat, :lng, :address, :city, :country

  def lat
    object.latitude
  end

  def lng
    object.longitude
  end
end