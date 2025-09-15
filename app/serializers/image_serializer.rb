class ImageSerializer < ActiveModel::Serializer
  attributes :link, :description

  def link
    object.url
  end
end
