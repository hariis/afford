# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  include FaceboxRender
  include ExceptionNotification::Notifiable

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password
  
  helper_method :current_user  
  before_filter :load_statistics

  unless ActionController::Base.consider_all_requests_local
    rescue_from Exception,                            :with => :render_error
    rescue_from ActiveRecord::RecordNotFound,         :with => :render_not_found
    rescue_from ActionController::RoutingError,       :with => :render_not_found
    rescue_from ActionController::UnknownController,  :with => :render_not_found
    rescue_from ActionController::UnknownAction,      :with => :render_not_found
  end

  def feedback
      store_location
      experience = Experience.new
      experience.feedback_type = Experience::COMMENT_TYPES.index(params[:feedback_type].to_i) if params[:feedback_type]
      experience.description = params[:description]
      experience.email = params[:email] if params[:email]
      Notifier.deliver_send_experience(experience)
      #render :nothing => true
      redirect_back_or_default(root_path)
  end
   
  private 

    def check_admin_user
      if current_user && current_user.username == 'admin'
        return true
      else
        render 'questions/404', :status => 404, :layout => false
        return
      end
    end
    
    def remove_commas(value)
      value.blank? ? 0 : value.gsub(/[,$]/,'')
    end

    def empty_if_default(value)
      value == "Example: Buy a Car" ? "" : value
    end

    def load_statistics
      if current_user
        @user_agreed_with_community = current_user.agreed_with_community
        @user_agreed_with_expert = current_user.agreed_with_expert
      end
    end
    
    def current_user_session  
      return @current_user_session if defined?(@current_user_session)  
      @current_user_session = UserSession.find  
    end  
      
    def current_user  
      @current_user = current_user_session && current_user_session.record  
    end  
      
    def store_location
      old_session_return_to = session[:return_to]
      session[:return_to] = request.env["HTTP_REFERER"] || request.request_uri
      if (session[:return_to].include?('login') || session[:return_to].include?('register'))        
         if old_session_return_to.include?('login') || old_session_return_to.include?('register') 
           session[:return_to] = nil
         else
           session[:return_to] = old_session_return_to
         end
      end
    end

    def redirect_back_or_default(default)
      redirect_to(session[:return_to] || default)
      session[:return_to] = nil
    end

    def force_logout
      current_user_session.destroy
      session[:return_to] = nil
    end
    
    def require_user
      unless current_user
        store_location
        #If someone double clicked the logout link, they come here and this flash notice doesn't make sense
        #flash[:notice] = "You must be logged in to access this page"
        redirect_to root_url
        return false
      end
    end

    def require_no_user
      if current_user
        store_location
        #If someone double clicked the logout link, they come here and this flash notice doesn't make sense
        #flash[:notice] = "You must be logged out to access this page"
        force_logout
        return true
        #redirect_to account_url
        #return false
      end
    end

    def validate_simple_email(email)
      unless email.blank?
          emailRE= /\A[\w\._%-]+@[\w\.-]+\.[a-zA-Z]{2,4}\z/
          return email =~ emailRE
      end
      return false
    end

    private

  def render_not_found(exception)
    log_error(exception)
    render :template => "/errors/404.html.erb", :status => 404, :layout => 'error'
  end

  def render_error(exception)
    log_error(exception)
    render :template => "/errors/500.html.erb", :status => 500, :layout => 'error'
  end
end
