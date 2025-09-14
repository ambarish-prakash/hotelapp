class Hotel < ApplicationRecord
  belongs_to :destination
  has_one :location, as: :owner, dependent: :destroy, autosave: true

  has_many :amenities, as: :owner, dependent: :destroy, inverse_of: :owner
  has_many :images,    as: :owner, dependent: :destroy, inverse_of: :owner

  validates :hotel_code, presence: true

  serialize :booking_conditions, coder: JSON
end
