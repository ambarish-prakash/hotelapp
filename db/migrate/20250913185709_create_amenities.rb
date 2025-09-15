class CreateAmenities < ActiveRecord::Migration[8.0]
  def change
    create_table :amenities do |t|
      t.references :owner, polymorphic: true, null: false
      t.string :category
      t.string :name

      t.timestamps

      t.index [ :owner_id, :owner_type, :category, :name ], unique: true, name: 'index_amenities_on_owner_and_category_and_name'
    end
  end
end
