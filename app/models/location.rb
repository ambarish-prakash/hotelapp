class Location < ApplicationRecord
  belongs_to :owner, polymorphic: true

  validates :owner_id, uniqueness: { scope: :owner_type }
end
