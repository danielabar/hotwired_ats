class CreateJobs < ActiveRecord::Migration[7.0]
  def change
    create_table :jobs do |t|
      t.string :title
      t.string :status, null: false, default: 'open'
      t.string :job_type, null: false, default: 'full_time'
      t.string :location
      t.references :account, null: false, foreign_key: true

      t.timestamps
    end
    add_index :jobs, :status
    add_index :jobs, :job_type
  end
end
