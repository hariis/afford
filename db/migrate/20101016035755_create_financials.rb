class CreateFinancials < ActiveRecord::Migration
  def self.up
    create_table :financials do |t|
      
      t.references :user
      
      t.integer :gross_income,                :null => false
      t.integer :net_income,                  :null => false
      t.integer :total_expenses,              :null => false
      t.integer :mortage_payment,             :default => 0
      t.integer :car_loan_payment,            :default => 0
      t.integer :student_loan_payment,        :default => 0
      t.integer :other_loan_payment,          :default => 0
      t.integer :deferred_loan_amount,        :default => 0
      t.integer :cc_debt,                     :default => 0
      t.integer :cc_interest_rate,            :default => 0
      t.integer :liquid_assets,               :default => 0
      t.integer :investments,                 :default => 0
      t.integer :retirement_savings,          :default => 0
      t.integer :monthly_retirement_contribution, :default => 0
      
      t.timestamps
    end
    add_index(:financials, :user_id)
  end

  def self.down
    drop_table :financials
  end
end
