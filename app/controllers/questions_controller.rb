class QuestionsController < ApplicationController
  layout 'application'
  before_filter :clear_stage_errors, :only => [:step1]
  before_filter :clear_stage_error_question_payment, :only => [:step3]
  before_filter :ensure_user_and_financial_exists, :only => [:payment_mode, :step3]
  before_filter :check_admin_user, :only => [:edit, :update, :destroy, :admin]
  
#  def method_missing(methodname, *args)
#    render 'questions/404', :status => 404, :layout => false
#  end
  
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
  
  def admin
    @users = User.find(:all).size
    @questions = Question.find(:all).size
    @responses = Response.find(:all).size
    @notification_new_question = Notification.find(:all, :conditions => ['question_id = ?', 0]).size
    @notification_new_responses = Notification.find(:all).size - @notification_new_question
  end
  
  # GET /questions
  # GET /questions.xml
  def index
    if current_user && current_user.username == 'admin'
      @questions = Question.find(:all, :order => 'created_at DESC', :limit => 5)
    else
      @questions = Question.find(:all, :conditions => ['nick_name != ? && expert_details is not NULL', "nickname"], :order => 'created_at DESC', :limit => 5)
    end

    #for the question
    if current_user && current_user.questions.size > 0
      @question = current_user.questions.find(:first, :order => 'created_at desc')
      @question.item_cost = ""
    else
      @question = Question.new
    end
    @question.item_name = "Example: Buy a Car"
    @reason_to_buy = "0"   

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @questions }
    end
  end

  def recent_posts
    if current_user && current_user.username == 'admin'
      @questions = Question.find(:all, :order => 'created_at DESC')
    else
      @questions = Question.find(:all, :conditions => ['nick_name != ? && expert_details is not NULL', "nickname"], :order => 'created_at DESC')
    end

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
    if current_user && current_user.questions.size > 0 
      @question = current_user.questions.find(:first, :order => 'created_at desc')
      @question.item_cost = ""
    else
      @question = Question.new
    end
    unless params[:want_to_buy].blank?
      @question.item_name = params[:want_to_buy]
    else
      @question.item_name = "Example: Buy a Car"
    end
    
    @reason_to_buy = "0"

    respond_to do |format|
      format.html 
      format.xml  { render :xml => @question }
    end
  end

  def edit
    @question = Question.find(params[:id])
    @reason_to_buy = @question.reason_to_buy
  end
 
  def update
    @question = Question.find(params[:id])

    respond_to do |format|
      if @question.update_attributes(params[:question])
        flash[:notice] = 'Question was successfully updated.'
        format.html { redirect_to(root_path) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @question.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @question = Question.find(params[:id])
    @question.destroy

    respond_to do |format|
      format.html { redirect_to(root_url) }
      format.xml  { head :ok }
    end
  end
    
  def step1
    #sanitize values    
    params[:question][:item_name] = empty_if_default(params[:question][:item_name])
    params[:question][:item_cost] = remove_commas(params[:question][:item_cost])
    params[:question][:recurring_item_cost] = remove_commas(params[:question][:recurring_item_cost])
    @question = Question.new(params[:question])
    
    #@question.nick_name = current_user.username if current_user
    
    #'reason_to_buy''age'
    #attributes_to_validate << 'nick_name' unless current_user
    #&& (current_user || @question.is_nick_name_unique)         
    attributes_to_validate = ['item_name','item_cost','recurring_item_cost']
    #attributes_to_validate << 'nick_name' unless current_user
    if Question.valid_for_attributes( @question, attributes_to_validate) #&& (current_user || @question.is_nick_name_unique)
      #.. Save user in session and go to step
      session[:new_question_item] = @question
      redirect_to :controller => :financials, :action => :new
    else
       #@reason_to_buy = @question.reason_to_buy
       @question.item_name = "Example: Buy a Car" if @question.item_name.blank?
       render :action => "index"
    end
  end
  
  def payment_mode
    #Ask payment details
    if current_user && current_user.questions.size > 0 
      @question = current_user.questions.find(:first, :order => 'created_at desc')
    else
      @question = Question.new
    end
    @item_cost = session[:new_question_item].item_cost if session[:new_question_item]
    @recurring_item_cost = session[:new_question_item].recurring_item_cost if session[:new_question_item]
  end
  
  def step3
    #Validate it
    #If successful, Store it in another session variable
    #else show errors for the last page
    
    params[:question][:pm_saving_amount] = remove_commas(params[:question][:pm_saving_amount])
    params[:question][:pm_investment_amount] = remove_commas(params[:question][:pm_investment_amount])
    params[:question][:pm_financing_amount] = remove_commas(params[:question][:pm_financing_amount])
    @question = Question.new(params[:question])
    @question.nick_name = current_user.username if current_user
        
    question_personal_item = session[:new_question_item]
    attributes_to_validate = ['pm_saving_amount','pm_investment_amount','pm_financing_amount', 'reason_to_buy', 'age']
    attributes_to_validate << 'nick_name' unless current_user
    if Question.valid_for_attributes( @question, attributes_to_validate ) && (current_user || @question.is_nick_name_unique)
        financial = session[:new_financial]
        #begin
            Question.validate_payment_details_input(@question, question_personal_item.item_cost, financial.investments)
            if @question.errors.size > 0
                @item_cost = question_personal_item.item_cost
                render :action => "payment_mode"
            else
                session[:new_question_payment] = @question
                redirect_to :controller => :financials, :action => :final
            end
    #    rescue
    #         @question.errors.add('Please try again', ": We are sorry something went wrong.")
    #         render :action => "new"
        #end
    else
        @reason_to_buy = @question.reason_to_buy
        @item_cost = question_personal_item.item_cost
        render :action => "payment_mode"
    end
  end
  
  def get_expert_verdict
    begin
        @question = Question.find(params[:id])
        unless @question.nil?
          @question.calculate_expert_verdict
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
  
  def privacy
  end

  def how
  end
  
  def subscribe
    if current_user && current_user.username == 'hari'
      Notifier.deliver_notify_on_new_question(1)
    end
    if validate_simple_email(params[:subscriber_email])
      if Notification.find(:all, :conditions => ['email = ? && question_id = ?', params[:subscriber_email], 0]).empty?
        #Save this data
        Notification.create(:email => params[:subscriber_email])
        render :text => 'Got it! Will do.'
      else
        render :text => 'Notification is already set for the given id.'
      end
    else
      render :text => 'Please enter a valid email address.'
    end    
  end
  
  def subscribe_responses
    question = Question.find(params[:qid]) if params[:qid]
    unless question.nil?
      if validate_simple_email(params[:subscriber_email])
        if Notification.find(:all, :conditions => ['email = ? && question_id = ?', params[:subscriber_email], question.id]).empty?
          #Save this data
          Notification.create(:email => params[:subscriber_email], :question_id => question.id)
          render :text => 'Got it! Will do.'
        else
          render :text => 'Notification is already set for the given id.'
        end
      else
        render :text => 'Please enter a valid email address.'
      end
    end
  end

  def rules_feedback
    sent = false
    unless params[:description].blank? || params[:description] == 'Let us know!'
      Notifier.deliver_send_rules_feedback(params[:description],params[:email])
      sent = true
    end
    render :update do |page|
      if sent
        page.hide "rules-feedback"
        page.replace_html "feedback-status", "Thank you for your valuable feedback"
      end
    end
  end

  def report_feedback
    sent = false
    unless params[:useful].blank?
        Notifier.deliver_send_report_feedback(params[:useful], params[:suggestion])
        sent = true
    end
    render :update do |page|
      if sent
        page.hide "rules-feedback"
        page.replace_html "feedback-status", "Thank you for your valuable feedback"
      end
    end
  end

  def new_question_notification
    question = Question.find(params[:id]) if params[:id]
    if question.nil?
        flash[:error] = "Error sending notification. Please try again"
    else
        notify_users = Notification.find(:all, :conditions => ['question_id = ?', 0])
        emails = ""
        notify_users.each do |user|
          emails << user.email
          emails << ","
        end
        Notifier.deliver_notify_on_new_question(question, emails.chop)
        flash[:notice] = "Notification send to all subscribe users"
    end   
    redirect_to root_path
  end
  
 def notify_on_product_updates
    if validate_simple_email(params[:subscriber_email])
      if Notification.find(:all, :conditions => ['email = ? and question_id = ?', params[:subscriber_email], -1]).empty?
        #Save this data
        Notification.create(:email => params[:subscriber_email], :question_id => -1)
        @message= 'Got it! Will do.'
      else
        @message=  'You are already subscribed to receive these updates. Thanks and Stay tuned.'
      end
    else
      @message=  'Please enter a valid email address.'
    end

   render :update do |page|
        page.replace_html "notification-status", @message
    end
  end
end
