# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password
  
  helper_method :current_user  
  before_filter :load_statistics

  private  
     def remove_commas(value)
      value.gsub(/,/,'') unless value.blank?
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
      session[:return_to] = request.env["HTTP_REFERER"] || request.request_uri
      session[:return_to] = nil if session[:return_to].include?('login')
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
end
