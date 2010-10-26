class AddCcDebtToFinancials < ActiveRecord::Migration
  def self.up
    add_column :financials, :cc_debt_at_zero, :integer, :default => 0
    add_column :financials, :cc_debt_gt_zero, :integer, :default => 0
    add_column :financials, :monthly_cc_payments_at_zero, :integer, :default => 0
    remove_column :financials, :cc_debt
    remove_column :financials, :cc_interest_rate
  end

  def self.down
    remove_column :financials, :cc_debt_at_zero
    remove_column :financials, :cc_debt_gt_zero
    remove_column :financials, :monthly_cc_payments_at_zero
    add_column :financials, :cc_debt, :integer, :default => 0
    add_column :financials, :cc_interest_rate, :integer, :default => 0
  end
end
