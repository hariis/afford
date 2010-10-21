class FinancialsController < ApplicationController
  layout 'application'
  before_filter :clear_stage_errors, :only => [:step2]
  before_filter :ensure_user_and_financial_exists, :only => [:final]
  
  def clear_stage_errors      
      unless session[:new_financial].nil?
        session[:new_financial] = nil
      end
  end
  
  def ensure_user_and_financial_exists
    session[:new_question_item] && session[:new_question_payment] && session[:new_financial]   
  end
  
  def new
    if current_user
      @financial = current_user.financials.find(:first, :order => 'created_at desc')
    else
      @financial = Financial.new
    end
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @financial }
    end
  end  

  def step2  
    @financial = Financial.new
    @financial.attributes = params[:financial]
    if Financial.valid_for_attributes( @financial, ['gross_income',  'net_income',  'total_expenses', 'liquid_assets', 'cc_interest_rate'] )
      #.. Save user in session and go to step
      Financial.validate_data_sanity(@financial)
      if @financial.errors.size > 0
        render :action => :new
      else
        session[:new_financial] = @financial
        redirect_to :controller => :questions, :action => :payment_mode
      end
    else
       render :action => :new
    end
  end

  def final
    #I don't why the before filter is not ending the chain if the session is nil
    #Thats why I have to catch it here and kick out the user
    unless ensure_user_and_financial_exists
      flash[:error] = 'You session has expired for security reasons. Please start again. <br/> Sorry for the incovenience.'
      redirect_to :controller => :questions, :action => :new and return
    end
    #If you are here all validation has passed
    #Create and save both Question and Financial models from session objects
    @financial = session[:new_financial]
    @question = session[:new_question_item]
    @question_payment = session[:new_question_payment]
    
    @question.pm_saving = @question_payment.pm_saving
    @question.pm_investment = @question_payment.pm_investment
    @question.pm_financing = @question_payment.pm_financing
    @question.pm_saving_amount = @question_payment.pm_saving_amount
    @question.pm_investment_amount = @question_payment.pm_investment_amount
    @question.pm_financing_amount = @question_payment.pm_financing_amount
    
    if @financial.save
        @question.financial_id = @financial.id
        if @question.save
            #SUPER IMPORTANT:
            #Clean session variables
            clear_session_variables
            redirect_to :action => :capture_additional_data, :id => @question.id
        end
    else
      flash[:error] = 'We are sorry but something went wrong. Please try again.'
      force_logout if current_user
      clear_session_variables
      redirect_to :controller => :questions, :action => :new
    end    
  end
  
  def capture_additional_data
      #Ask for email to send the expert_opinion and password to save the financial_data
      @question = Question.find(params[:id])
      if current_user
          force_logout
          redirect_to :controller => :questions, :action => :get_expert_verdict, :id => @question.id and return
      end
  end
  
  def create_account
    #TODO Send report and create user account
    #email = params[:email]        
    @question = Question.find(params[:id])
    @error_msg = ""
    
    unless params[:password].empty?
        @error_msg << "Password is too short (minimum is 4 characters)<br/>" if params[:password].size < 4
        @user = User.new
        nick_name = params[:nick_name]
        if nick_name.include?("@")   #=> true
          @error_msg << "Nick name should not have '@' character <br/>"
        else
          @user.username = nick_name  
          @user.password = params[:password]
          @user.password_confirmation = params[:password]
          if @user.save
            @question.update_attributes(:nick_name => nick_name)          
            @question.update_attributes(:user_id => @user.id)
            @question.financial.update_attributes(:user_id => @user.id)
          else
            @error_msg << "Username has already been taken"
          end
        end
    end
    unless @error_msg.empty?
      flash[:error] = @error_msg      
      redirect_to :action => :capture_additional_data, :id => @question.id
      #TODO clean up error message not displaying properly
      return        
    end   
    force_logout if current_user
    redirect_to :controller => :questions, :action => :get_expert_verdict, :id => @question.id
  end
  
  def clear_session_variables
    #SUPER IMPORTANT:
    #Clean session variables
    session[:new_question_item] = nil
    session[:new_question_payment] = nil
    session[:new_financial] = nil
  end
  
end
