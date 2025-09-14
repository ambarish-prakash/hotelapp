class CreateHotels < ActiveRecord::Migration[8.0]
  def change
    create_table :hotels do |t|
      t.references :destination, null: false, foreign_key: true

      t.string :hotel_code, null: false
      t.string :name
      t.string :description
      t.text :booking_conditions

      t.timestamps
    end
    
    add_index :hotels, :hotel_code, unique: true
  end
end
