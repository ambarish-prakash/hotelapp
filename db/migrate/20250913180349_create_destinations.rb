class CreateDestinations < ActiveRecord::Migration[8.0]
  def change
    create_table :destinations do |t|
      t.string :name

      t.timestamps
    end
  end
end
