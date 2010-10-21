class QuestionsController < ApplicationController
  layout 'application'
  before_filter :clear_stage_errors, :only => [:step1]
  before_filter :clear_stage_error_question_payment, :only => [:step3]
  before_filter :ensure_user_and_financial_exists, :only => [:payment_mode, :step3]
  
  def clear_stage_errors
      unless session[:new_question_item].nil?
        session[:new_question_item] = nil
      end         
      unless session[:new_financial].nil?
        session[:new_financial] = nil
      end
  end
  
  def clear_stage_error_question_payment
     unless session[:new_question_payment].nil?
        session[:new_question_payment] = nil
      end   
  end
  
  def ensure_user_and_financial_exists
    session[:new_question_item] && session[:new_financial]
  end
  
  # GET /questions
  # GET /questions.xml
  def index
    @questions = Question.find(:all, :order => 'created_at DESC')

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @questions }
    end
  end

  def show
    @question = Question.find(params[:id])
    @financial = @question.financial
    @response = Response.new  
  end
  
  def new
    @question = Question.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @question }
    end
  end
  
  def step1
    @question = Question.new(params[:question])
    if current_user
      @question.nick_name = current_user.username
    end
    if Question.valid_for_attributes( @question, ['item_name','reason_to_buy','item_cost','recurring_item_cost','age', 'nick_name'] )
      #.. Save user in session and go to step
      session[:new_question_item] = @question
      redirect_to :controller => :financials, :action => :new
    else
       render :action => "new"
    end
  end
  
  def payment_mode
    #Ask payment details
    @question = Question.new
  end
  
  def step3
    #Validate it
    #If successful, Store it in another session variable
    #else show errors for the last page
    @question = Question.new(params[:question])
    #if Question.valid_for_attributes( @question, ['pm_saving','pm_investment','pm_financing','pm_saving_amount','pm_investment_amount','pm_financing_amount'] )
    #TODO: Correct displaying of error messages
    question_personal_item = session[:new_question_item]
    
    begin
        Question.validate_payment_details_input(@question, question_personal_item.item_cost)
        if @question.errors.size > 0
            render :action => "payment_mode"
        else
            session[:new_question_payment] = @question
            redirect_to :controller => :financials, :action => :final
        end
    rescue
         @question.errors.add('Please try again', ": We are sorry something went wrong.")
         render :action => "new"
    end
  end
  
  def get_expert_verdict
    begin
        @question = Question.find(params[:id])
        unless @question.nil?
          @question.get_expert_verdict
          @expert_details = @question.expert_details
          @expert_verdict = @question.expert_verdict
        end
    rescue
        @question.errors.add('Please try again', ": We are sorry something went wrong.")
        render :action => "new"
    end
    @financial = @question.financial
  end
  
  def tos  
  end
  
  def about
  end
  
  def subscribe
    #Notifier.deliver_notify_on_new_question(params[:subscriber_email],1)
    
    if validate_simple_email(params[:subscriber_email])
      #Save this data
      Notification.create(:email => params[:subscriber_email])
      render :text => 'Got it! Will do.'
    else
      render :text => 'Please enter a valid email address.'
    end    
  end
end
