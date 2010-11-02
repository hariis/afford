class AddQidToNotification < ActiveRecord::Migration
  def self.up
    add_column :notifications, :question_id, :integer, :default => 0
  end

  def self.down
    remove_column :notifications, :question_id
  end
end
