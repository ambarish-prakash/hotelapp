class CreateImages < ActiveRecord::Migration[8.0]
  def change
    create_table :images do |t|
      t.references :owner, polymorphic: true, null: false
      t.string :category
      t.string :url

      t.timestamps
    end
  end
end
