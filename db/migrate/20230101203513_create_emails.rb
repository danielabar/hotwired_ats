class CreateEmails < ActiveRecord::Migration[7.0]
  def change
    create_table :emails do |t|
      t.references :applicant, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :subject
      t.datetime :sent_at

      t.timestamps
    end
  end
end
