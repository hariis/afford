class UserSessionsController < ApplicationController
  
  def new
    store_location
    @user_session = UserSession.new
    @login_text = "Nick Name"
      if params[:reg] == 'email'
        @login_text = "Email"
      end
  end

  def create
   @user_session = UserSession.new(params[:user_session]) 
   valid_email = validate_simple_email(params[:user_session][:username])
   proceed = true
   error_text = ''
   if params[:reg] == 'Email'
     unless valid_email
       error_text = ": For responding, please use your Email to login"
       @user_session.errors.add(:username,error_text)
       proceed = false
     end
   else
     if valid_email
       error_text = ": For Asking a Question, please use your Nick Name to login"
       @user_session.errors.add(:username,error_text)
       proceed = false
     end
   end
   if proceed && @user_session.save
     flash[:notice] = "Successfully logged in."  
     redirect_back_or_default(root_url)
   else
     @login_text = params[:reg]
     render :action => 'new'  
   end
  end

  def destroy
    @user_session = UserSession.find  
    @user_session.destroy  
    flash[:notice] = "Successfully logged out."  
    redirect_to root_url  
  end

end
