class CreateResponses < ActiveRecord::Migration
  def self.up
    create_table :responses , :force => true do |t|
      t.boolean :verdict
      t.text :reason
      t.references :question
      t.references :user
      t.timestamps
    end
    add_index :responses, :question_id
    add_index :responses, :user_id
  end

  def self.down
    drop_table :responses
  end
end
