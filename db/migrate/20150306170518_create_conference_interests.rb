class CreateConferenceInterests < ActiveRecord::Migration
  def change
    create_table :conference_interests do |t|
      t.integer :conference_id
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
