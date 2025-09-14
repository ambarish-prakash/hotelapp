class Amenity < ApplicationRecord
  belongs_to :owner, polymorphic: true
end
