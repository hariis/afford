class UsersController < ApplicationController
   layout "application"

   before_filter :redirect_to_error, :except => [:new, :create]
  
   def redirect_to_error
      render 'questions/404', :status => 404, :layout => false and return
   end
  
  def new
     store_location
     @user = User.new
  end  

   def create
     @user = User.new(params[:user])
     @user.password_confirmation = @user.password

     if @user.save
       flash[:notice] = "Successfully registered."
       redirect_back_or_default(root_url)
     else
       render :action => 'new'
     end     
   end

#   def edit  
#      @user = current_user
#    end
#
#   def update
#      @user = current_user
#      @user.password_confirmation = @user.password
#      if @user.update_attributes(params[:user])
#        flash[:notice] = "Successfully updated profile."
#        redirect_to root_url
#     else
#       render :action => 'edit'
#     end
#   end
#    def destroy
#      if current_user.username == 'hari2' || current_user.username == 'satish'
#        current_user.destroy
#      end
#    end
end