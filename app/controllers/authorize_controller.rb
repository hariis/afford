class AuthorizeController < ApplicationController
  def callback
    access_token = OAuthClient.web_server.access_token(
      params[:code], :redirect_uri => auth_callback_url
    )    
    @user = User.find(session[:uid]) if session[:uid]
    @fb_user = FacebookUser.create_from_fb(access_token,@user.id)

  end

end
