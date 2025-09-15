class CreateImages < ActiveRecord::Migration[8.0]
  def change
    create_table :images do |t|
      t.references :owner, polymorphic: true, null: false
      t.string :category
      t.string :url
      t.string :description

      t.timestamps

      t.index [ :owner_id, :owner_type, :url ], unique: true, name: 'index_images_on_owner_and_url'
    end
  end
end
