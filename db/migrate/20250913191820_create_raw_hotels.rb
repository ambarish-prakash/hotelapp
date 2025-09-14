class CreateRawHotels < ActiveRecord::Migration[8.0]
  def change
    create_table :raw_hotels do |t|
      t.references :destination, null: false, foreign_key: true

      t.string :name
      t.string :description
      t.text :booking_conditions
      
      t.string :source
      t.string :hotel_code, null: false
      t.json :raw_json

      t.timestamps
    end

    add_index :raw_hotels, [:hotel_code, :source], unique: true
  end
end
