class Question < ActiveRecord::Base
  belongs_to :financial, :dependent => :destroy
  belongs_to :user
  has_many :responses, :order => 'created_at DESC', :dependent => :destroy
  
  after_create :new_question_notification_to_admin
  
  REASON_TO_BUY = { "Please Select One" => "0", "I Deserve/Earned It" => "1", "I Need It" => "2", "Nice To Have" => "3", "Just Like That" => "4"}
  #REASON_TO_BUY = { "0" => "Please Select One", "1" => "I Deserve/Earned It", "2" => "I Need It", "3" => "Nice To Have", "4" => "Just Like That" }
  
  validates_length_of :item_name, :minimum => 5
  validates_length_of :nick_name, :minimum => 3
  validates_format_of :nick_name, :with => /^[A-Za-z\d_]+$/, :message => "can contain only alphabets, numerals and underscores"
  #validates_uniqueness_of :nick_name
  validates_exclusion_of :nick_name, :in => %w( moderator admin superuser ___ ), :message => "Please choose a different one"

  validates_numericality_of :recurring_item_cost, :pm_saving_amount, :pm_investment_amount, :pm_financing_amount, :greater_than_or_equal_to => 0, :only_integer => true 

  def new_question_notification_to_admin
    Notifier.deliver_notify_on_new_question(self, "satish.fnu@gmail.com, hrajagopal@yahoo.com")
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
  
  def is_nick_name_unique
    #first check in User table
    exists = User.find_by_username(nick_name)
    if exists
      self.errors.add('nick_name',' already taken! Please choose a different one.')
    else
      exists = Question.find_by_nick_name(nick_name)
      if exists
        self.errors.add('nick_name',' already taken! Please choose a different one.')
      end
    end
    status = self.errors.empty? ? true : false;
    return status
  end

  def self.validate_payment_details_input(question, item_cost, investments)
    if question.pm_saving_amount < 0 || question.pm_investment_amount < 0 || question.pm_financing_amount < 0
      question.errors.add("Values", " for payment mode must be greater than or equal to 0")
    end
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
  
  def community_response_approved
    responses.find(:all, :conditions => ['verdict = ?', true])
  end
  
  def community_response_denied
    responses.find(:all, :conditions => ['verdict = ?', false])
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
    check_rule5_total_loan_payment
    check_rule6_deferred_loan   
    check_rule7_item_cost_at_retirement
    
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
  
  def regular_deposit_in_future(contribution, years)
    r = 0.08/12.0
    n = years * 12 
    amount = ((1+r)**n-1)/r
    total_amount = contribution * amount
    total_amount.to_i
  end
  
  def compound_interest(item_cost, years)
    r = 0.08
    factor = (1+r)**years
    ci = item_cost*factor
    return ci.to_i
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
                        "approximately " + (financial.cc_debt_at_zero.to_f / monthly_savings.to_f).to_s + " months" : "less than a month"
          @expert_details << "Note: At your current monthly savings of $#{monthly_savings}, it will take #{months_to_cover} to pay off the debt outright.</li>"
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
        else
          @expert_verdict = false
          @expert_details << "<li class='red'>Your $#{addon_liquid_assets} <b>Liquid assets / Savings</b> remaining after this purchase is not sufficient to cover for your emergency fund. <br/>Recommended is 6 times your total monthly expenses.</li>"
        end
      else
          @expert_verdict = false
          @expert_details << "<li class='red'>Your $#{addon_liquid_assets} <b>Liquid assets / Savings</b> remaining after this purchase is not sufficient to cover for your emergency fund. <br/>Recommended is 6 times your total monthly expenses.</li>"
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
    rdiff = financial.monthly_retirement_contribution - rcontribution
    
    #if (financial.monthly_retirement_contribution >= rcontribution)
    if (rdiff >= 0)
      @expert_details << "<li class='green'>Your $#{financial.monthly_retirement_contribution} monthly <b>retirement contribution</b> is good.</li>"
    else
      #@expert_details << "<li class='red'>Based on your age & income, $#{financial.monthly_retirement_contribution} monthly <b>retirement contribution</b> is less by $#{(rcontribution-financial.monthly_retirement_contribution).to_i}</li>"
      if self.age <= 40
        @expert_details << "<li class='red'>Based on your age, $#{financial.monthly_retirement_contribution} monthly <b>retirement contribution</b> is less than 8% of your net income.</li>"
      else
        @expert_details << "<li class='red'>Based on your age, $#{financial.monthly_retirement_contribution} monthly <b>retirement contribution</b> is less than 10% of your net income.</li>"
      end
      @expert_verdict = false
      cost = regular_deposit_in_future(rdiff.abs, 65-self.age)
      @expert_details << "<li class='red'>Expert suggests: You are $#{rdiff.abs.to_i} behind your monthly <b>retirement contribution</b>. Being behind by $#{rdiff.abs.to_i} each month you will reduce your retirement nest by $#{cost}.</li>"
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
  
  def check_rule5_total_loan_payment
    #Total loan payment + Recurring Loan Payment for item < 36% of Gross monthly income. (+- 4%)
    if addon_total_loan_payment <= 0.36 * financial.gross_income
       @expert_details << "<li class='green'>Your $#{addon_total_loan_payment} <b>Total Loan Payments</b> are less than or equal to 36% of your Gross income.</li>"
    elsif addon_total_loan_payment <= 0.40 * financial.gross_income
        #loan_payment = (addon_total_loan_payment/financial.gross_income)*100 - 36 
        gap = addon_total_loan_payment - (0.36 * financial.gross_income)
        @expert_details << "<li class='green'>Your $#{addon_total_loan_payment}<b> Total Loan Payments</b> are slightly greater than 36% of your Gross income.<br/>
                          Expert suggests: You can still buy this item if you can reduce your total monthly loan payments by $#{gap.to_i}</li>"
    else
        @expert_verdict = false
        @expert_details << "<li class='red'>Your $#{addon_total_loan_payment} <b>Total Loan Payments</b> are greater than 36% of your Gross Income.</li>"
        return false
    end
  end
  
  def check_rule6_deferred_loan
    #if Deferred loans > 0, item cost < 1000
    if financial.deferred_loan_amount <= 0     
      @expert_details << "<li class='green'>Your have no <b>Deferred loans</b> which is good.</li>"
    elsif @expert_verdict == true #you are clean. no deniel from the previous rule
      @expert_details << "<li class='green'>You have some deferred loans but you are doing well with your finances. Make sure to pay off your loan sooner than later.</li>"
    elsif @expert_verdict == false #you are are mess. few deniels from the previous rule
      @expert_verdict = false
      @expert_details << "<li class='red'>You have <b>Deferred loans</b> in the amount of $#{financial.deferred_loan_amount}.<br/>
                        Expert suggests: Start paying off your Deferred loans first. This will save you money in the long run.</li>"
    end
  end
  
 def check_rule7_item_cost_at_retirement
    if self.age < 55 #todo check if this is ok
       cost = compound_interest(self.item_cost, 65-self.age)
       #x = app_number_to_currency(cost)
       @expert_details << "<hr/>Expert suggests: The $#{self.item_cost} item purchased now will be equivalent to $#{cost} at the age of 65. Please be sure that you really want to do this"
    end
  end
  
  def  app_number_to_currency(value)
     number_to_currency(value, :precision => 0)
  end
  
  #-------------------------------------------------------------------------------
end