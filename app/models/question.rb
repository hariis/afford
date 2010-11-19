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
    @total_duration = 0
    
    @addon_total_expenses = financial.total_expenses + self.recurring_item_cost + self.pm_financing_amount
    
    #Liquid assets - item cost to be paid from savings
    @addon_liquid_assets = financial.liquid_assets - self.pm_saving_amount
      
    #All loan payment + Recurring Loan Payment for item  + Credit card payment for the 0% rate loan
    @addon_total_loan_payment = financial.mortage_payment + financial.car_loan_payment +
                                financial.student_loan_payment + financial.other_loan_payment + 
                                financial.monthly_cc_payments_at_zero + self.pm_financing_amount  
  
    #investments - item cost to be paid from investment
    @addon_investment = financial.investments - self.pm_investment_amount
    @monthly_savings = financial.net_income - @addon_total_expenses
     
    @expected_retirement_contribution = 0.08 * financial.net_income if self.age <= 40
    @expected_retirement_contribution = 0.10 * financial.net_income if self.age > 40
    @retirement_deficit = financial.monthly_retirement_contribution >= @expected_retirement_contribution ? 0 :
                          @expected_retirement_contribution - financial.monthly_retirement_contribution
    @retirement_nest_deficit = regular_deposit_in_future(@retirement_deficit.abs, 65-self.age) if @retirement_deficit.abs > 0

    @expected_emergency_funds = 6 * @addon_total_expenses
    @emergency_funds_deficit =  @addon_liquid_assets >= @expected_emergency_funds ? 0 : @expected_emergency_funds - @addon_liquid_assets
    @emergency_funds_deficit_tolerance = 0.05 * @expected_emergency_funds
 
    check_rule1_income_expenses
    check_rule2_credit_cart_debt
    check_rule3_liquid_assets
    #check_rule4_retirement_payment
    check_rule4_retirement_payment_current
    check_rule5_total_loan_payment
    check_rule6_deferred_loan   
    check_rule7_item_cost_at_retirement
    check_rule8_total_duration
    
    self.update_attributes(:expert_verdict => @expert_verdict)        
    self.update_attributes(:expert_details => @expert_details)
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
  
  def expert_recommend1_income_expenses
    @expert_details << "<li class='expert-notes'>Expert Notes: Please start a savings plan and/or generate more Income.
                     Some helpful link to save and make more money.<br/>
                     http://www.getrichslowly.org/blog/2008/04/08/66-ways-to-save-money/<br/>
                     http://www.getrichslowly.org/blog/2010/11/10/make-more-money-how-to-supercharge-your-income/</li>"
  end
  
  def expert_recommend2_credit_cart_debt
    if @monthly_savings > 0.0
      duration = financial.cc_debt_gt_zero.to_f / @monthly_savings.to_f
      @total_duration += duration     
      if duration < 12.0
          months_to_cover = duration < 1.0 ? "less than a month" : "approximately #{duration.to_i} month(s)"
          @expert_details << "<li class='expert-notes'>Expert Notes: If you start contributing your current monthly savings of #{@monthly_savings.to_currency} towards your Credit card debt,
                                it will take #{months_to_cover} to pay off your credit card debt.</li>"
      end
    else
        @expert_details << "<li class='expert-notes'>Expert Notes: Consider paying off your <b>Credit card debt</b> first.</li>"
    end
  end
  
  def expert_recommend3_liquid_assests

    if @monthly_savings > 0.0       
        duration = @emergency_funds_deficit.to_f / @monthly_savings.to_f
       
        if (@total_duration + duration) < 12.0
            months_to_cover = duration < 1.0 ? "less than a month" : "approximately #{duration.to_i} months" 
            if @total_duration == 0
                @expert_details << "<li class='expert-notes'>Expert Notes: If you start contributing your current monthly savings of #{@monthly_savings.to_currency} towards it,
                          it will take #{months_to_cover} to have the recommended amount.</li>"
            else
                  @expert_details << "<li class='expert-notes'>Expert Notes: Once your Credit card loan is paid off, if you start contributing your current monthly savings of #{@monthly_savings.to_currency} towards it,
                          it will take #{months_to_cover} to have the recommended amount.</li>"
            end
        end
        @total_duration += duration
    end
  end
  
  def expert_recommend5_total_loan_payment    
    #@expert_details << "<li class='expert-notes'>Expert Notes: Please follow the link to learn how to reduce the loan payment</li>"
  end
  
  def expert_recommend6_deferred_loan
    #@expert_details << "<li class='expert-notes'>Please follow the link to learn about deferred loan</li>"   
  end
  
  #---------------------------------------------------------------------------------------------------------
  def check_rule1_income_expenses
    #Is Net Income > Expenses + Recurring Expenses + Recurring Loan Payment for item
    if @monthly_savings >= 0      
      @expert_details << "<li class='green'>Your Total monthly expenses will be #{@addon_total_expenses.to_currency} after the purchase."
      @expert_details << " It will still be within your Net Income.</li>"
    else
      @expert_verdict = false
      includes = []
      includes << "recurring cost of the item " if self.recurring_item_cost > 0
      includes << "recurring loan payment for the item " if self.pm_financing_amount > 0
      include_string = includes.size > 0 ? " including " + includes.to_sentence : ""
      @expert_details << "<li class='red'>Your Total monthly expenses #{include_string}  will be #{@addon_total_expenses.to_currency} after the purchase."
      @expert_details << " It will exceed your Net Income by #{(@monthly_savings * -1).to_currency}.</li>"
      expert_recommend1_income_expenses
    end
     @expert_details << "<br/>"
  end
  
  def check_rule2_credit_cart_debt
    #check if cc_debt_gt_zero > 0
    #add :monthly_cc_payments_at_zero to total loan payments
    if financial.cc_debt_gt_zero <= 0
      if financial.cc_debt_at_zero <= 0
        @expert_details << "<li class='green'>You have no <b>Credit card debt.</b></li>"
      else
        @expert_details << "<li class='green'>You have #{financial.cc_debt_at_zero.to_currency} in <b>Credit card debt</b> @ 0 % interest rate.</li>"
        if financial.monthly_cc_payments_at_zero > 0
          @expert_details << "<li class='expert-notes'>Expert Notes: You are already making monthly payments on this.<br/>"
        else
          @expert_details << "<li class='expert-alert'>Expert Notes: You are not yet making monthly payments on this.
                          Consider paying off your <b>Credit card debt</b> first.<br/>"
        end
        #Add a comment as to how long it will take to pay off outright from savings
        if @monthly_savings > 0
          months_to_cover = financial.cc_debt_at_zero > @monthly_savings ?
                        "approximately #{(financial.cc_debt_at_zero.to_f / @monthly_savings.to_f).to_i} month(s)" : "less than a month"
          @expert_details << "At your current monthly savings of #{@monthly_savings.to_currency}, it will take #{months_to_cover} to pay off the debt outright.</li>"
        else
          @expert_details << "</li>"
        end

      end
    else      
      if @monthly_savings >= financial.cc_debt_gt_zero
         @expert_details << "<li class='green'>You have #{financial.cc_debt_gt_zero.to_currency} in <b>Credit card debt</b> @ more than 0 % interest rate.</li>"
         @expert_details << "<li class='expert-alert'>Expert Notes: Your monthly savings of #{@monthly_savings.to_currency} is adequate to clear your Credit card debt.
                  Consider paying it off first.</li>"
      else
        @expert_verdict = false
        @expert_details << "<li class='red'>You have #{financial.cc_debt_gt_zero.to_currency} in <b>Credit card debt</b> @ more than 0 % interest rate.</li>"
        expert_recommend2_credit_cart_debt
      end
    end
    @expert_details << "<br/>"
  end
  
  def check_rule3_liquid_assets    
    if @emergency_funds_deficit > 0
      if (@addon_investment >= (8 * @addon_total_expenses) - @addon_liquid_assets) && (self.reason_to_buy == 1 || self.reason_to_buy == 2)
          @expert_details << "<li class='green'>You are short of your Emergency fund by #{@emergency_funds_deficit.to_currency}, however you do have some <b>Investments. </b><br/>"
          #Recommend this only if the deficit is significant like 5%
          @expert_details << "Since you said that you deserve it or need it, you can first secure your Emergency fund by liquidating #{@emergency_funds_deficit.to_currency} from your <b>Investments</b> and moving it to <b>Savings</b> and then make the purchase.</li>" if @emergency_funds_deficit > @emergency_funds_deficit_tolerance
      else          
          if @monthly_savings >= @emergency_funds_deficit + financial.cc_debt_gt_zero
            @expert_details << "<li class='green'>You are short of your Emergency fund by #{@emergency_funds_deficit.to_currency}, however you do have some <b>Monthly Savings</b>. <br/>"
            @expert_details << "<li class='expert-alert'>Expert Notes: Your monthly savings of #{@monthly_savings.to_currency} is sufficient to cover the Emergency fund deficit.</b>
                  Consider earmarking #{@emergency_funds_deficit.to_currency} for your Emergency fund from your current monthly savings to cover the deficit.</li>"
          else  
              #consider the tolerance before failing
              #before denying, check for the tolerance
              if @emergency_funds_deficit > @emergency_funds_deficit_tolerance
                @expert_verdict = false
                @expert_details << "<li class='red'>Your <b>Liquid Assets / Savings</b> of #{@addon_liquid_assets.to_currency} remaining after this purchase is not sufficient to cover your Emergency fund. You are short by #{@emergency_funds_deficit.to_currency}. Recommended Emergency fund is 6 times your Total Monthly expenses.</li>"
              else
                @expert_details << "<li class='green'>You are short of your Emergency fund by less than 5% of the recommended amount which is #{@emergency_funds_deficit.to_currency}. Recommended Emergency fund is 6 times your Total Monthly expenses.</li>"
              end              
              expert_recommend3_liquid_assests
          end
      end
    else
      @expert_details << "<li class='green'>You have adequate <b>Liquid Assets / Savings</b> for your Emergency fund.</li>"
    end
    @expert_details << "<br/>"
  end
  
  def check_rule4_retirement_payment_current
    #TODO retirement monthly contribution > = supposed to be (from lookup table)    
    if @retirement_deficit == 0
      @expert_details << "<li class='green'>Your #{financial.monthly_retirement_contribution.to_currency} monthly <b>retirement contribution</b> is good.</li>"
    else
      if @expert_verdict && (@monthly_savings >= @emergency_funds_deficit + financial.cc_debt_gt_zero + @retirement_deficit.abs)
        @expert_details << "<li class='green'>Based on your age, your monthly <b>retirement contribution</b> of #{financial.monthly_retirement_contribution.to_currency} is less than 8% of your net income.</li>" if age <= 40
        @expert_details << "<li class='green'>Based on your age, your monthly <b>retirement contribution</b> of #{financial.monthly_retirement_contribution.to_currency} is less than 10% of your net income.</li>" if age > 40
        @expert_details << "<li class='expert-alert'>Expert Notes: You are short by #{@retirement_deficit.abs.to_i.to_currency}. However you have sufficient funds in your monthly savings to cover it.
                      Consider paying yourself first by contributing #{@retirement_deficit.abs.to_i.to_currency} from your current monthly savings toward your <b>Retirement</b>. Note that this can increase your retirement nest egg by #{@retirement_nest_deficit.to_currency} at age 65.</li>"
      else
        
        if age > 30          
          @expert_verdict = false
          @expert_details << "<li class='red'>Based on your age, your monthly <b>retirement contribution</b> of #{financial.monthly_retirement_contribution.to_currency} is less than 8% of your net income.</li>" if age <= 40
          @expert_details << "<li class='red'>Based on your age, your monthly <b>retirement contribution</b> of #{financial.monthly_retirement_contribution.to_currency} is less than 10% of your net income.</li>" if age > 40
        else
          @expert_details << "<li class='green'>Based on your age, your monthly <b>retirement contribution</b> of #{financial.monthly_retirement_contribution.to_currency} is less than 8% of your net income.</li>" if age <= 40
          @expert_details << "<li class='green'>Based on your age, your monthly <b>retirement contribution</b> of #{financial.monthly_retirement_contribution.to_currency} is less than 10% of your net income.</li>" if age > 40
          @expert_details << "<li class='expert-alert'>Expert Notes: Since you are less than 30, your lack of contribution towards retirement is overlooked.</li>"
        end
         @expert_details << "<li class='expert-notes'>Expert Notes: You are #{@retirement_deficit.abs.to_i.to_currency} behind in your monthly <b>retirement contributions</b>. Note that this can lower your retirement nest egg by #{@retirement_nest_deficit.to_currency} at age 65.</li>"      
      end
    end 
    @expert_details << "<br/>"
  end
  
  def check_rule5_total_loan_payment
    #Total loan payment + Recurring Loan Payment for item < 36% of Gross monthly income. (+- 4%)
    if @addon_total_loan_payment <= 0.36 * financial.gross_income
       @expert_details << "<li class='green'>Your <b>Total Loan Payments</b> of #{@addon_total_loan_payment.to_currency} are less than or equal to 36% of your Gross income.</li>"
    elsif @addon_total_loan_payment <= 0.40 * financial.gross_income
        #loan_payment = (addon_total_loan_payment/financial.gross_income)*100 - 36 
        gap_to_catchup = @addon_total_loan_payment - (0.36 * financial.gross_income)
        @expert_details << "<li class='green'>Your #{@addon_total_loan_payment.to_currency}<b> Total Loan Payments</b> are slightly greater than 36% of your Gross income.</li>
                          <li class='expert-alert'>Expert Notes: You can still buy this item if you can reduce your Total Monthly loan payments by #{gap_to_catchup.to_i.to_currency}</li>"
    else
        @expert_verdict = false
        @expert_details << "<li class='red'>Your #{@addon_total_loan_payment.to_currency} <b>Total Loan Payments</b> are greater than 36% of your Gross Income.</li>"
        expert_recommend5_total_loan_payment
        #return false
    end
    @expert_details << "<br/>"
  end
  
  def check_rule6_deferred_loan
    #if Deferred loans > 0, item cost < 1000
    if financial.deferred_loan_amount <= 0     
      @expert_details << "<li class='green'>Your have no <b>Deferred loans</b>.</li>"
    elsif @expert_verdict == true #you are clean. no denial from the previous rules
      @expert_details << "<li class='green'>You have some Deferred loans but you are doing well otherwise with your finances. Make sure to pay off your loan sooner than later.</li>"
    elsif @expert_verdict == false #you are in a mess. few denials from the previous rules
      @expert_verdict = false
      @expert_details << "<li class='red'>You have <b>Deferred loans</b> in the amount of #{financial.deferred_loan_amount.to_currency}.</li>
                        <li class='expert-notes'>Expert Notes: Start paying off your loans. This can save you money in the long run.</li>"
    end
    expert_recommend6_deferred_loan if financial.deferred_loan_amount > 0 
    #@expert_details << "<br/>"
  end
  
 def check_rule7_item_cost_at_retirement
    if self.age < 55 #todo check if this is ok
      if self.pm_saving_amount > 0 || self.pm_investment_amount > 0
         cash_down = self.pm_saving_amount + self.pm_investment_amount
         final_cost = compound_interest(cash_down, 65-self.age)
         @expert_details << "<li class='expert-tips'>Expert Tips: #{(cash_down.to_currency)} invested now at 8% yearly returns would be worth #{final_cost.to_currency} at the age of 65."
      end
    end
  end

  def check_rule8_total_duration
    if @expert_verdict == false && @monthly_savings > 0 && (@addon_total_loan_payment <= 0.40 * financial.gross_income) && @total_duration < 12.0
      if (@retirement_deficit >= 0)
          how_long_before_you_can_afford_it = @total_duration < 1.0 ? "less than a month" : "approximately #{@total_duration.to_i} months" 
          @expert_details << "<li class='expert-tips'>If you follow the suggested guidelines, it will take #{how_long_before_you_can_afford_it} month(s) before you can afford this item</li>"
      end
    end
  end
  
  #-------------------------------------------------------------------------------
end

require 'rubygems'
require 'action_view'

class Fixnum
  def to_currency(options = {:precision => 0})
    ActionView::Base.new.number_to_currency(self, options)
  end
end