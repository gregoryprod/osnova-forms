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

ActiveRecord::Schema[8.1].define(version: 2026_10_30_000100) do
  create_table "submissions", force: :cascade do |t|
    t.string "client_submission_id", null: false
    t.text "payload", null: false
    t.string "payload_digest", null: false
    t.string "status", default: "pending", null: false
    t.integer "attempts", default: 0, null: false
    t.string "last_error"
    t.string "amo_uid"
    t.bigint "amo_lead_id"
    t.bigint "amo_contact_id"
    t.datetime "next_attempt_at"
    t.datetime "lease_until"
    t.datetime "delivered_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_submission_id"], name: "index_submissions_on_client_submission_id", unique: true
    t.index ["status", "next_attempt_at"], name: "index_submissions_on_status_and_next_attempt_at"
  end
end
