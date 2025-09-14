class CreateHotels < ActiveRecord::Migration[8.0]
  def change
    create_table :hotels, id: :string do |t|
      t.references :destination, null: false, foreign_key: true

      t.string :name
      t.string :description
      t.text :booking_conditions

      t.timestamps
    end
  end
end
