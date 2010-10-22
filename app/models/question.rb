class Question < ActiveRecord::Base
  belongs_to :financial
  belongs_to :user
  has_many :responses, :order => 'created_at DESC'
  
  REASON_TO_BUY = { "I Deserve/Earned It" => "1", "I Need It" => "2", "Nice To Have" => "3", "Just Like That" => "4"}
  
  validates_presence_of :item_name, :reason_to_buy, :nick_name
  validates_numericality_of :recurring_item_cost
      
  validates_each :age, :on => :save do |record,attr,value|
      if value.blank?
        record.errors.add(attr,": Please enter your #{attr.to_s.humanize}")
      elsif !Question.is_a_number?(value.to_i)
        record.errors.add(attr,": Please enter a valid value")
      else
        case attr
        when :age:
            if value.to_i < 20 || value.to_i > 65 then
                record.errors.add(attr,": We have data for ages between 20 and 65 only.")
            end
        end
      end
  end
  
  validates_each :item_cost, :on => :save do |record,attr,value|
      if value.blank?
        record.errors.add(attr,": Please enter the item cost")
      elsif !Question.is_a_number?(value.to_i)
        record.errors.add(attr,": Please enter a valid value")
      else
        case attr
        when :item_cost:
            if value.to_i < 100 || value.to_i > 1000000 then
                record.errors.add(attr,": We can calculate for cost between 100 and 1 million only.")
            end
        end
      end
  end
  
 def self.is_a_number?(s)
    s.to_s.sub(/,/,'').match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true
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

  def self.validate_payment_details_input(question, item_cost)
    if question.pm_saving == false && question.pm_investment == false && question.pm_financing == false
        question.errors.add("Please", " select atleast one payment mode")
    else
        if question.pm_saving == true && (question.pm_saving_amount.nil? || question.pm_saving_amount <= 0)
          question.errors.add("Please", " enter your Contribution from Savings")
        end

        if question.pm_investment == true && (question.pm_investment_amount.nil? || question.pm_investment_amount <= 0)
          question.errors.add("Please",  " enter your Contribution from Investments")
        end

        if question.pm_financing == true && (question.pm_financing_amount.nil? || question.pm_financing_amount <= 0)
          question.errors.add("Please", " enter your monthly Payment")
        end
        #TODO additional validation
        #only savings - item cost should be equal to pm_saving_amount
        #only investment - item cost should be equal to pm_investment_amount
        unless question.errors.size > 0
          if question.pm_saving == true && question.pm_investment == false && question.pm_financing == false
            if question.pm_saving_amount != item_cost
              question.errors.add("Your", "contribution from Savings does not match the Item cost of $#{item_cost}")
            end
          end
          if question.pm_investment == true && question.pm_saving == false && question.pm_financing == false
            if question.pm_investment_amount != item_cost              
              question.errors.add("Your", " contribution from Investments does not match the Item cost of $#{item_cost}")
            end
          end
          if question.pm_investment == true && question.pm_saving == true && question.pm_financing == false
            if question.pm_investment_amount + question.pm_saving_amount != item_cost
              question.errors.add("Your", " contribution from Savings and Investments does not match the Item cost of $#{item_cost}")
            end
          end
        end
    end    
  end

  def is_responded_by(user)
    responses.find_by_user_id(user.id) != nil
  end
  
  def response_for(user)
    responses.find_by_user_id(user.id)
  end

  def get_community_verdict(user_verdict)
    positive_responses = responses.find(:all, :conditions => ['verdict = ?', true])
    if positive_responses.size == responses.size/2
      return true
    else
      community_verdict = positive_responses.size > (responses.size - positive_responses.size)
      user_verdict == community_verdict
    end
  end
  
  #Financial Rules
  #---------------------------------------------------------------------------------------------------------
  def get_expert_verdict
    @expert_details = ""
    @expert_verdict = true
    
    check_rule1_income_expenses
    check_rule2_credit_cart_debt
    check_rule3_liquid_assets
    check_rule4_retirement_payment
    check_rule5_deferred_loan
    check_rule6_total_loan_payment
    check_rule7_investment
    
    self.update_attributes(:expert_verdict => @expert_verdict)        
    self.update_attributes(:expert_details => @expert_details)
  end
  
  def addon_total_expenses
    #Expenses + Recurring Expenses + Recurrring Loan Payment for item    
    financial.total_expenses + self.recurring_item_cost + self.pm_financing_amount
  end
  
  def addon_liquid_assets
    #Liquid assets - item cost to be paid from savings
    financial.liquid_assets - self.pm_saving_amount     
  end
  
  def addon_total_loan_payment
    #All loan payment + Recurrring Loan Payment for item   
    financial.mortage_payment + financial.car_loan_payment +
    financial.student_loan_payment + financial.other_loan_payment +
    self.pm_financing_amount
  end
  
  def addon_investment
    #investments - item cost to be paid from investment
    financial.investments - self.pm_investment_amount
  end
  
  #---------------------------------------------------------------------------------------------------------
  def check_rule1_income_expenses
    #Is Net Income > Expenses + Recurring Expenses + Recurrring Loan Payment for item
    diff = financial.net_income - addon_total_expenses
    if diff >= 0
      #@expert_details << "Your <b>Net Income</b> is good to match the <b>Total Expenses</b><br/>"
      @expert_details << "<li class='green'>Your Total monthly expenses will be $#{addon_total_expenses} after the purchase"
      @expert_details << " which will still be within your Net income.</li>"
    else
      @expert_verdict = false
      includes = []
      includes << "recurring cost of the item " if self.recurring_item_cost > 0
      includes << "recurring loan payment for the item " if self.pm_financing_amount > 0
      include_string = includes.size > 0 ? " including" + includes.to_sentence : ""
      @expert_details << "<li class='red'>Your Total monthly expenses #{include_string}  will be $#{addon_total_expenses} after the purchase"
      @expert_details << " which will EXCEED your Net income by $#{diff * -1}.</li>"
      #@expert_details << "<span class='red'>Your <b>Net Income</b> is/will be less than Total Expenses "
      #@expert_details << "+ Recurring cost of the item " if self.recurring_item_cost > 0
      #@expert_details << "+ Recurring loan payment for the item " if self.pm_financing_amount > 0
      #@expert_details << "to support this purchase</span><br/>"
    end
  end
  
  def check_rule2_credit_cart_debt
    #Credit card debt <= 0 || (cc_debt > 0 && interest rate = 0
    if financial.cc_debt <= 0 || (financial.cc_interest_rate == 0 &&  financial.cc_debt <= 2000)
      if financial.cc_debt <= 0 
        @expert_details << "<li class='green'>Your have no <b>Credit card debt.</b></li>"
      else
        @expert_details << "<li class='green'>Your have some <b>Credit card debt</b> @ 0% which is acceptable</li>"
      end
    else
      @expert_verdict = false
      @expert_details << "<li class='red'>You have $#{financial.cc_debt} <b>Credit card debt</b> @ #{financial.cc_interest_rate}%.<br/>
                          Expert suggests: Pay off your <b>Credit card debt</b> before buying this item.</li>"
    end    
  end
  
  def check_rule3_liquid_assets
    #Liquid assets > 6 * Expenses 
    #liquid assets(Liquid assets - item cost to be paid from savings) > 6 * Expenses (Expenses + Recurring Expenses + Recurrring Loan Payment for item)
    net_liquid = addon_liquid_assets < 6 * addon_total_expenses
    if net_liquid
      move_funds = (6 * addon_total_expenses) - addon_liquid_assets
      if (addon_investment >= (8 * addon_total_expenses) - addon_liquid_assets)
          @expert_details << "<li class='green'>You don't have sufficient <b>Liquid assets / Savings</b> for your emergency fund but you do have some <b>Investments </b><br/>"
          @expert_details << "Since you said that you deserve it or need it, You can liquidate $#{move_funds} from your <b>Investments</b> to <b>Savings</b> and then make the purchase.</li>" if self.reason_to_buy == 1 || self.reason_to_buy == 2
      else
          @expert_verdict = false
          @expert_details << "<li class='red'>You don't have sufficient <b>Liquid assets / Savings</b> to cover for your emergency fund. <br/>Recommeded is 6 times your total monthly expenses.</li>"
      end
    else
      @expert_details << "<li class='green'>You have adequate <b>Liquid assets / Savings</b> for your emergency fund.</li>"
    end
  end
  
  def check_rule4_retirement_payment
    #retirement monthly contribution > = supposed to be (from lookup table)    
    #TODO 
    if (financial.monthly_retirement_contribution >= 0.10*financial.net_income)
      @expert_details << "<li class='green'>You are making $#{financial.monthly_retirement_contribution} monthly contribution towards retirement which is good.</li>"
    else
      @expert_details << "<li class='red'>Based on your income, your $#{financial.monthly_retirement_contribution} monthly contribution towards retirement is very less.</li>"
      @expert_verdict = false
    end
  end
  
  def check_rule5_deferred_loan
    #if Deferred loans > 0, item cost < 1000
    if financial.deferred_loan_amount <= 0     
      @expert_details << "<li class='green'>Your have no <b>Deferred loans</b> which is good.</li>"
    elsif (self.item_cost <= 1000 && (self.reason_to_buy == 1 || self.reason_to_buy == 2) )
      @expert_details << "<li class='green'>Even though you have some deferred loans, since you mentioned that you deserve it or need it, you can go ahead if you are so inclined. Make sure to pay off your loan sooner than later.</li>"
    else
      @expert_verdict = false
      @expert_details << "<li class='red'>You mentioned you have some <b>Deferred loans</b> in the amount of $#{financial.deferred_loan_amount}.<br/>
                        Expert suggests: Start paying off your Deferred loans first. This will save you money in the long run.</li>"
    end
  end

  def check_rule6_total_loan_payment
    #Total loan payment + Recurrring Loan Payment for item < 36% of Gross monthly income. (+- 4%)
    if addon_total_loan_payment < 0.36 * financial.gross_income
       @expert_details << "<li class='green'>Your <b>Total Loan Payments</b> are less than 36% of your Gross income which is sound.</li>"
    else
      if addon_total_loan_payment < 0.40 * financial.gross_income
        loan_payment = (addon_total_loan_payment/financial.gross_income)*100 - 36
        @expert_details << "<li class='green'>Your <b>Total Loan Payments</b> are slightly greater than 36% of your Gross income.<br/>
                          Expert suggests: You can still buy this item if you can reduce your total monthly loan payments by $#{loan_payment}%</li>"
      else
        @expert_verdict = false
        @expert_details << "<li class='red'>Your <b>Total Loan Payments</b> are too high to support this purchase.</li>"
      end
      return false
    end
  end

  def check_rule7_investment
    #additional checking when all the above rule are true
    #paying from the investment
    if self.pm_investment_amount > 0 #if you are paying from investment
      if addon_investment > 0
        @expert_details << "<li class='green'>You have sufficient funds in your Investments to support this purchase.</li>"
      else
        @expert_verdict = false
        @expert_details << "<li class='red'>You don't have sufficient funds in your investments to support this purchase.</li>"
      end
    end
  end
  #---------------------------------------------------------------------------------------------------------
end