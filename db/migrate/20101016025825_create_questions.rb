class CreateQuestions < ActiveRecord::Migration
  def self.up
    create_table :questions do |t|
      t.references :financial
      t.references :user
       
      t.string :item_name,            :null => false
      t.integer :item_cost,           :null => false
      t.integer :reason_to_buy,       :null => false    
      t.integer :recurring_item_cost, :default => 0
      t.integer :age,                 :null => false
      t.string  :nick_name,           :null => false
      t.text    :expert_details
      t.boolean :expert_verdict
        
      t.boolean :pm_saving
      t.boolean :pm_investment
      t.boolean :pm_financing
      t.integer :pm_saving_amount,     :default => 0
      t.integer :pm_investment_amount, :default => 0
      t.integer :pm_financing_amount,  :default => 0

      t.boolean :tos,                  :default => false
      t.timestamps
    end
    
    add_index(:questions, :financial_id)
    add_index(:questions, :user_id)
   
  end

  def self.down
    drop_table :questions
  end
end
