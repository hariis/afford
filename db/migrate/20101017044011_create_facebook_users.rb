class CreateFacebookUsers < ActiveRecord::Migration
  def self.up
    create_table :facebook_users do |t|
      t.references :user
      t.string :facebook_id
      t.string :name
      t.string :first_name
      t.string :last_name
      t.string :link
      t.string :email
      t.integer :timezone
      t.string :token

      t.timestamps
    end
  end

  def self.down
    drop_table :facebook_users
  end
end

