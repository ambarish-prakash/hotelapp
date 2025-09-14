# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_13_191820) do
  create_table "amenities", force: :cascade do |t|
    t.string "owner_type", null: false
    t.integer "owner_id", null: false
    t.string "category"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id"], name: "index_amenities_on_owner"
  end

  create_table "destinations", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "hotels", id: :string, force: :cascade do |t|
    t.integer "destination_id", null: false
    t.string "name"
    t.string "description"
    t.text "booking_conditions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["destination_id"], name: "index_hotels_on_destination_id"
  end

  create_table "images", force: :cascade do |t|
    t.string "owner_type", null: false
    t.integer "owner_id", null: false
    t.string "category"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id"], name: "index_images_on_owner"
  end

  create_table "locations", force: :cascade do |t|
    t.string "owner_type", null: false
    t.string "owner_id", null: false
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "address"
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id"], name: "index_locations_on_owner"
    t.index ["owner_type", "owner_id"], name: "index_locations_on_owner_type_and_owner_id", unique: true
  end

  create_table "raw_hotels", id: :string, force: :cascade do |t|
    t.integer "destination_id", null: false
    t.string "name"
    t.string "description"
    t.text "booking_conditions"
    t.string "source"
    t.string "hotel_id"
    t.json "raw_json"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["destination_id"], name: "index_raw_hotels_on_destination_id"
  end

  add_foreign_key "hotels", "destinations"
  add_foreign_key "raw_hotels", "destinations"
end
