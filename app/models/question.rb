class Question < ActiveRecord::Base
  belongs_to :financial
  belongs_to :user
  has_many :responses, :order => 'created_at DESC'
  
  after_save :new_question_notification
  
  REASON_TO_BUY = { "Please Select One" => "0", "I Deserve/Earned It" => "1", "I Need It" => "2", "Nice To Have" => "3", "Just Like That" => "4"}
  #REASON_TO_BUY = { "0" => "Please Select One", "1" => "I Deserve/Earned It", "2" => "I Need It", "3" => "Nice To Have", "4" => "Just Like That" }
  
  validates_presence_of :item_name, :nick_name
  #validates_numericality_of :recurring_item_cost, :pm_saving_amount, :pm_investment_amount, :pm_financing_amount
  validates_numericality_of :recurring_item_cost

  def new_question_notification
    Notifier.deliver_notify_on_new_question(self.id)
  end
  
  validates_each :reason_to_buy, :on => :save do |record,attr,value|
     if value.to_i == 0 then
        #record.errors.add("Please", " select a valid reason") #//Not sure why but this does not work
        record.errors.add(attr,": Please select a valid reason")
     end
  end
  
  validates_each :pm_saving_amount, :on => :save do |record,attr,value|      
    Financial.is_blank_or_not_number(record,attr,value)
  end 
  validates_each :pm_investment_amount, :on => :save do |record,attr,value|      
    Financial.is_blank_or_not_number(record,attr,value)
  end
  validates_each :pm_financing_amount, :on => :save do |record,attr,value|      
    Financial.is_blank_or_not_number(record,attr,value)
  end
  
  validates_each :age, :on => :save do |record,attr,value|
      if value.blank?
        record.errors.add(attr,": Please enter your #{attr.to_s.humanize}")
      elsif !Question.is_a_number?(value.to_i)
        record.errors.add(attr,": Please enter a valid value")
      else
        case attr
        when :age:
            if value.to_i < 20 || value.to_i > 65 then
                record.errors.add(attr,": We have data for ages between 20 and 65 only")
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
                record.errors.add(attr,": We can calculate for cost between $100 and $1 million only")
            end
        end
      end
  end
  
 def self.is_a_number?(s)
    s.to_s.gsub(/,/,'').match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true
 end
  
 def self.is_blank_or_not_number(value)
     if value.blank?
        return true
      elsif !Question.is_a_number?(value.to_i)
        return true
      end
      return false
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

  def self.validate_payment_details_input(question, item_cost, investments)
    unless question.errors.size > 0
      if question.pm_saving_amount <= 0 && question.pm_investment_amount <= 0 && question.pm_financing_amount <= 0
          question.errors.add("Please", " enter amount for atleast one payment mode")    
      else
          #TODO additional validation
          #only savings - item cost should be equal to pm_saving_amount
          #only investment - item cost should be equal to pm_investment_amount
          if question.pm_saving_amount > 0 && question.pm_investment_amount <= 0 && question.pm_financing_amount <= 0
            if question.pm_saving_amount != item_cost
              question.errors.add("Your", " contribution from Savings does not match the Item cost of $#{item_cost}")
            end
          end

          if question.pm_investment_amount > 0 && question.pm_saving_amount <= 0 && question.pm_financing_amount <= 0
            if question.pm_investment_amount != item_cost
              question.errors.add("Your", " contribution from Investments does not match the Item cost of $#{item_cost}")
            end
          end

          if question.pm_saving_amount > 0 && question.pm_investment_amount > 0 && question.pm_financing_amount <= 0
            if question.pm_saving_amount + question.pm_investment_amount != item_cost
              question.errors.add("Your", " contribution from Savings and Investments does not match the Item cost of $#{item_cost}")
            end
          end  

          unless question.errors.size > 0
            if question.pm_investment_amount > 0
              unless investments - question.pm_investment_amount >= 0
                question.errors.add("Your", " investments fund of $#{investments} is not sufficient to support this purchase")
              end
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
  def calculate_expert_verdict
    @expert_details = ""
    @expert_verdict = true
    
    check_rule1_income_expenses
    check_rule2_credit_cart_debt
    check_rule3_liquid_assets
    #check_rule4_retirement_payment
    check_rule4_retirement_payment_current
    check_rule5_deferred_loan
    check_rule6_total_loan_payment
    
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
    #All loan payment + Recurrring Loan Payment for item  + Credit card payment for the 0% rate loan
    financial.mortage_payment + financial.car_loan_payment +
    financial.student_loan_payment + financial.other_loan_payment + financial.monthly_cc_payments_at_zero + 
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
      include_string = includes.size > 0 ? " including " + includes.to_sentence : ""
      @expert_details << "<li class='red'>Your Total monthly expenses #{include_string}  will be $#{addon_total_expenses} after the purchase"
      @expert_details << " which will exceed your Net income by $#{diff * -1}.</li>"
      #@expert_details << "<span class='red'>Your <b>Net Income</b> is/will be less than Total Expenses "
      #@expert_details << "+ Recurring cost of the item " if self.recurring_item_cost > 0
      #@expert_details << "+ Recurring loan payment for the item " if self.pm_financing_amount > 0
      #@expert_details << "to support this purchase</span><br/>"
    end
  end
  
  def check_rule2_credit_cart_debt
    #check if cc_debt_gt_zero > 0
    #add :monthly_cc_payments_at_zero to total loan payments
    if financial.cc_debt_gt_zero <= 0
      if financial.cc_debt_at_zero <= 0
        @expert_details << "<li class='green'>Your have no <b>Credit card debt.</b></li>"
      else
        @expert_details << "<li class='green'>Your have $#{financial.cc_debt_at_zero} <b>Credit card debt</b> @ 0 % interest.<br/>"
        if financial.monthly_cc_payments_at_zero > 0
          @expert_details << "You are already making monthly payments on this.</li>"
        else
          @expert_details << "You are not yet making monthly payments on this. <br/>
                          Expert suggests: Start paying off your <b>Credit card debt</b> first.<br/>"
        end
        #Add a comment as to how long it will take to pay off outright from savings
        monthly_savings = financial.net_income - addon_total_expenses
        if monthly_savings > 0
          months_to_cover = financial.cc_debt_at_zero > monthly_savings ?
                        (financial.cc_debt_at_zero.to_f / monthly_savings.to_f).to_s + " months" : "less than a month"
          @expert_details << "Note:At your current monthly savings of $#{monthly_savings}, it will take approximately #{months_to_cover.to_i} to pay off the debt outright.</li>"
        else
          @expert_details << "</li>"
        end

      end
    else
      @expert_verdict = false
      @expert_details << "<li class='red'>You have $#{financial.cc_debt_gt_zero} <b>Credit card debt</b> @ more than 0 % interest.<br/>
                          Expert suggests: Pay off your <b>Credit card debt</b> first.</li>"
    end
    
  end
  
  def check_rule3_liquid_assets
    #Liquid assets > 6 * Expenses 
    #liquid assets(Liquid assets - item cost to be paid from savings) > 6 * Expenses (Expenses + Recurring Expenses + Recurring Loan Payment for item)
    net_liquid = addon_liquid_assets < 6 * addon_total_expenses
    if net_liquid
      move_funds = (6 * addon_total_expenses) - addon_liquid_assets
      if (addon_investment >= (8 * addon_total_expenses) - addon_liquid_assets)
        if self.reason_to_buy == 1 || self.reason_to_buy == 2
          @expert_details << "<li class='green'>You don't have 6 times your total monthly expenses in <b>Liquid assets / Savings</b> for your emergency fund but you do have some <b>Investments. </b><br/>"
          @expert_details << "Since you said that you deserve it or need it, you can first secure your emergency fund by liquidating $#{move_funds} from your <b>Investments</b> and moving it to <b>Savings</b> and then make the purchase.</li>"
        end
      else
          @expert_verdict = false
          @expert_details << "<li class='red'>You don't have sufficient <b>Liquid assets / Savings</b> to cover for your emergency fund. <br/>Recommended is 6 times your total monthly expenses.</li>"
      end
    else
      @expert_details << "<li class='green'>You have adequate <b>Liquid assets / Savings</b> for your emergency fund.</li>"
    end
  end
  
  def check_rule4_retirement_payment_old
    #retirement monthly contribution > = supposed to be (from lookup table)    
    #TODO 
    if (financial.monthly_retirement_contribution >= 0.10*financial.net_income)
      @expert_details << "<li class='green'>You are making $#{financial.monthly_retirement_contribution} monthly contribution towards retirement which is good.</li>"
    else
      @expert_details << "<li class='red'>Based on your income, your $#{financial.monthly_retirement_contribution} monthly contribution towards retirement is very less.</li>"
      @expert_verdict = false
    end
  end

  def check_rule4_retirement_payment_current
    #retirement monthly contribution > = supposed to be (from lookup table)    
    #TODO
    rcontribution = 0.08*financial.net_income if self.age <= 40
    rcontribution = 0.10*financial.net_income if self.age > 40
    
    if (financial.monthly_retirement_contribution >= rcontribution)
      @expert_details << "<li class='green'>Your $#{financial.monthly_retirement_contribution} monthly <b>retirement contribution</b> is good.</li>"
    else
      @expert_details << "<li class='red'>Based on your age & income, $#{financial.monthly_retirement_contribution} monthly <b>retirement contribution</b> is less by $#{(rcontribution-financial.monthly_retirement_contribution).to_i}</li>"
      @expert_verdict = false
    end
  end
  
  def check_rule4_retirement_payment_future1
    lookup = Ratio.find(:first, :conditions => ['age = ?', (self.age-self.age%5)])
    unless lookup.nil?
      saving_diff = lookup.captial_to_income * financial.gross_income - financial.retirement_savings
      if saving_diff > 0
          @expert_verdict = false
          @expert_details << "<li class='red'>Your $#{financial.retirement_savings} retirement savings is still below by $#{saving_diff}.<br/>
                              Expert suggests: Increase your <b>retirement contribution<b/> to match the deficit of $#{saving_diff}.</li>"
      else
          @expert_details << "<li class='green'>Your $#{financial.retirement_savings} retirement saving is good.</li>"
      end
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
      @expert_details << "<li class='red'>You mentioned that you have some <b>Deferred loans</b> in the amount of $#{financial.deferred_loan_amount}.<br/>
                        Expert suggests: Start paying off your Deferred loans first. This will save you money in the long run.</li>"
    end
  end

  def check_rule6_total_loan_payment
    #Total loan payment + Recurring Loan Payment for item < 36% of Gross monthly income. (+- 4%)
    if addon_total_loan_payment <= 0.36 * financial.gross_income
       @expert_details << "<li class='green'>Your <b>Total Loan Payments</b> are less than or equal to 36% of your Gross income.</li>"
    elsif addon_total_loan_payment <= 0.40 * financial.gross_income
        #loan_payment = (addon_total_loan_payment/financial.gross_income)*100 - 36
        gap = addon_total_loan_payment - (0.36 * financial.gross_income)
        @expert_details << "<li class='green'>Your <b>Total Loan Payments</b> are slightly greater than 36% of your Gross income.<br/>
                          Expert suggests: You can still buy this item if you can reduce your total monthly loan payments by $#{gap.to_i}</li>"
    else
        @expert_verdict = false
        @expert_details << "<li class='red'>Your <b>Total Loan Payments</b> are greater than 36% of your Gross Income.</li>"
        return false
    end
  end
  #---------------------------------------------------------------------------------------------------------
end