class CreateAmenities < ActiveRecord::Migration[8.0]
  def change
    create_table :amenities do |t|
      t.references :owner, polymorphic: true, null: false
      t.string :category
      t.string :name

      t.timestamps
    end
  end
end
