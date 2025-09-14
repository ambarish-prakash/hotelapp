class CreateRawHotels < ActiveRecord::Migration[8.0]
  def change
    create_table :raw_hotels, id: :string do |t|
      t.references :destination, null: false, foreign_key: true

      t.string :name
      t.string :description
      t.text :booking_conditions
      
      t.string :source
      t.string :hotel_id
      t.json :raw_json

      t.timestamps
    end
  end
end
