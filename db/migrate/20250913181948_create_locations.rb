class CreateLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :locations do |t|
      t.references :owner, polymorphic: true, null: false, index: true
      t.decimal :latitude,  precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string  :address
      t.string  :city
      t.string  :country
      t.timestamps
    end

    add_index :locations, [:owner_type, :owner_id], unique: true
  end
end
