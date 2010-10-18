class UsersController < ApplicationController
   layout "application"
    
   def new
     store_location
      @user = User.new
      @login_text = "Nick Name"
      if params[:reg] == 'email'
        @login_text = "Email"
      end
   end  

   def create
     @user = User.new(params[:user])
     @user.password_confirmation = @user.password

     valid_email = validate_simple_email(params[:user][:username])
     proceed = true
     error_text = ''

     unless valid_email
       error_text = ": Please use a valid Email address to register"
       @user.errors.add(:username,error_text)
       proceed = false
     end

     if proceed && @user.save
       flash[:notice] = "Successfully registered."
       redirect_back_or_default(root_url)
     else
       render :action => 'new'
     end     
   end

   def edit  
      @user = current_user  
    end  
      
   def update  
      @user = current_user
      @user.password_confirmation = @user.password
      if @user.update_attributes(params[:user])  
        flash[:notice] = "Successfully updated profile."  
        redirect_to root_url  
     else  
       render :action => 'edit'  
     end  
   end  
  
end
