class ResponsesController < ApplicationController
  before_filter :load_question
  before_filter :require_user,  :only => [:new, :create]
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
      end
    
  end
end
