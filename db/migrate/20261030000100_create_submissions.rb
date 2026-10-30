class CreateSubmissions < ActiveRecord::Migration[8.1]
  def change
    create_table :submissions do |t|
      t.string :client_submission_id, null: false
      t.text :payload, null: false
      t.string :payload_digest, null: false
      t.string :status, null: false, default: "pending"
      t.integer :attempts, null: false, default: 0
      t.string :last_error
      t.string :amo_uid
      t.bigint :amo_lead_id
      t.bigint :amo_contact_id
      t.datetime :next_attempt_at
      t.datetime :lease_until
      t.datetime :delivered_at
      t.timestamps
    end
    add_index :submissions, :client_submission_id, unique: true
    add_index :submissions, [:status, :next_attempt_at]
  end
end
