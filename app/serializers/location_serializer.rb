class LocationSerializer < ActiveModel::Serializer
  attributes :lat, :lng, :address, :city, :country

  def lat
    object.latitude.to_f
  end

  def lng
    object.longitude.to_f
  end
end
