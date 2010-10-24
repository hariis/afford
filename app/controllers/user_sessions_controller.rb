class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:destroy]
#   before_filter :redirect_to_error, :except => [:new, :create, :destroy]
#
#   def redirect_to_error
#      render 'questions/404', :status => 404, :layout => false and return
#   end
     
  def new
    store_location
    @user_session = UserSession.new
  end

  def create
   @user_session = UserSession.new(params[:user_session]) 

   if @user_session.save
     flash[:notice] = "Successfully logged in."  
     redirect_back_or_default(root_url)
   else
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