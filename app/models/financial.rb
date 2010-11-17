class Financial < ActiveRecord::Base
  has_many :questions
  belongs_to :user
  
  accepts_nested_attributes_for :questions  
  
  validates_numericality_of :mortage_payment, :car_loan_payment, :student_loan_payment, :other_loan_payment, :deferred_loan_amount, 
                            :cc_debt_at_zero, :monthly_cc_payments_at_zero, :cc_debt_gt_zero, :investments, :retirement_savings,
                            :monthly_retirement_contribution, :greater_than_or_equal_to => 0, :only_integer => true

  
 validates_each :gross_income, :on => :save do |record,attr,value|
     unless self.is_blank_or_not_number(record,attr,value)       
       if value.to_i < 2500 || value.to_i > 8000 then
          record.errors.add(attr,": Currently we support between $2,500 and $8,000 only.")
       #if value.to_i < 2500 then
          #record.errors.add(attr,": Currently we support amount over $2,500 only.")
       end
     end
  end
  
  validates_each :net_income, :on => :save do |record,attr,value|      
      unless self.is_blank_or_not_number(record,attr,value)
       if value.to_i < 1000 || value.to_i > 8000 then
          record.errors.add(attr,": Currently we support between $1,000 and $8,000 only.")
       #if value.to_i < 1000 then
          #record.errors.add(attr,": Currently we support amount over $1,000 only.")
       elsif value.to_i >= record.gross_income.to_i
          record.errors.add(attr,": Net Income should be less than Gross Income.")
       end
     end
  end
  
  validates_each :total_expenses, :on => :save do |record,attr,value|      
      unless self.is_blank_or_not_number(record,attr,value)
       if value.to_i < 500 || value.to_i * 12 > 100000 then
          record.errors.add(attr,": Currently we support between $500/mo and $8,300/mo only.")
       #if value.to_i < 500 then
          #record.errors.add(attr,": Currently we support amount over $500/mo. only")
       elsif value.to_i <= (self.get_total_loan_payments(record))
          record.errors.add(attr,": Total Monthly Expenses should take into account all loan payments and living expenses.")
       end
       #if value.to_i < 500 || value.to_i > 100000 then
       #   record.errors.add(attr,"Currently we support between $500 and $100,000 only.")
       #end
     end
  end
  
  validates_each :liquid_assets, :on => :save do |record,attr,value|     
     unless self.is_blank_or_not_number(record,attr,value)
       if value.to_i < 1000 || value.to_i > 1000000 then
          record.errors.add(attr,": Currently we support between $1000 and $1,000,000 only.")
       end
       #if value.to_i < 1000 || value.to_i > 100000 then
       #   record.errors.add(attr,"Currently we support between $1000 and $100,000 only.")
       #end
     end
  end
  def self.get_total_loan_payments(record)
    record.monthly_cc_payments_at_zero.to_i + record.mortage_payment.to_i + record.car_loan_payment.to_i +
      record.student_loan_payment.to_i + record.other_loan_payment.to_i
  end
  
  def self.is_blank_or_not_number(record,attr,value)
     if value.blank?
        record.errors.add(attr,": Please enter your #{attr.to_s.humanize}")
        return true
      elsif !Question.is_a_number?(value.to_i)
        record.errors.add(attr,": Please enter a valid value")
        return true
      end
      return false
  end
  
  validates_each :retirement_savings, :on => :save do |record,attr,value|
        #if value.to_i < 0 || value.to_i > 100000 then
        #    record.errors.add(attr,": We have data to support between 0 and $100,000 only.")
  end  
  
  def self.valid_attribute?(attrib, value)
    mock = self.new(attrib => value)
    unless mock.valid?
      return !mock.errors.on(attrib).present?
    end
    true
  end
  
  # Might be a good addition to AR::Base
  def self.valid_for_attributes( model, attributes )
      unless model.valid?
        errors = model.errors
        our_errors = Array.new
        errors.each { |attr,error|
          if attributes.include? attr
            our_errors << [attr,error]
          end
        }
        errors.clear
        our_errors.each { |attr,error| errors.add(attr,error) }
        return false unless errors.empty?
      end
      return true
  end
  
  def self.validate_data_sanity(financial)
    if financial.net_income > financial.gross_income
      financial.errors.add(:net_income, ": Net income should be less than gross income")
    end
  end
end
