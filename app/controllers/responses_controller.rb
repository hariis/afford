class ResponsesController < ApplicationController
  before_filter :load_question, :except => [:destroy]
  before_filter :require_user,  :only => [:new, :create, :statistics]
  before_filter :check_admin_user, :only => [:destroy]
  
  def method_missing(methodname, *args)
    render 'questions/404', :status => 404, :layout => false
  end
    
  def load_question
    @question = Question.find(params[:id])
  end
  
  def new
    @response = Response.new
  end
  
  def create
    if params[:response][:verdict].nil? || params[:response][:reason].blank?
      @status_string = 'Please make sure to provide your response and reasoning.'
      @result = false
    else
      @response = Response.new(params[:response])
      @response.user_id = current_user.id
      @status_string = ""
      @result = false
      if @question.responses << @response
        @status_string = "Thank you!"
        @result = true
      else
        @status_string = 'Error saving :( Please try again'
      end
    end
    
    render :update do |page|
        page.replace_html 'prompt-user-response', @status_string if @result
        page.hide "user-response" if @result
        page.replace_html 'user-response-status', "" if @result
        page.replace_html 'user-response-status', @status_string unless @result
        page.insert_html :bottom, 'all-responses', :partial => 'response', :object => @response, :locals => {:response_counter => @question.responses.size - 1}
      end

  end   
  
  def destroy
    @response = Response.find(params[:id])
    question = @response.question
    @response.destroy

    respond_to do |format|
      format.html { redirect_to(:controller => :questions, :action => :show, :id => question.id ) }
      format.xml  { head :ok }
    end
  end

end
