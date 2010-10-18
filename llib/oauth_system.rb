require 'json'
require 'oauth/consumer'

module OauthSystem
	class GeneralError < StandardError
	end
	class RequestError < OauthSystem::GeneralError
	end
	class NotInitializedError < OauthSystem::GeneralError
	end

	# controller method to handle logout
	def signout
		self.current_user = false 
		flash[:notice] = "You have been logged out."
		redirect_to root_url
	end
	
	# controller method to handle twitter callback (expected after login_by_oauth invoked)
	def callback
		begin
      @post = Post.find(session[:post_id]) if session[:post_id]
			self.twitagent.exchange_request_for_access_token( session[:request_token], session[:request_token_secret], params[:oauth_verifier] )
			
			user_info = self.twitagent.verify_credentials
			
			raise OauthSystem::RequestError unless user_info['id'] && user_info['screen_name'] && user_info['profile_image_url']
			
			# We have an authorized user, save the information to the database.
			@user = User.find_by_unique_id(session[:uid]) if session[:uid]
			if @user
        @user.screen_name = user_info['screen_name']
				@user.token = self.twitagent.access_token.token
				@user.secret = self.twitagent.access_token.secret
				#@member.profile_image_url = user_info['profile_image_url']
			else
				flash[:error] = "Unable to locate the user"
			end
			if @user.save!
				self.current_user = @user
			else
				raise OauthSystem::RequestError
			end
      
      flash[:notice] = "We have successfully accessed your Twitter account. <br/><br/>
                        Please click on the 'Invite Friends' link on your post page to see your followers and invite them."
      #redirect_to @post.get_url_for(@user,'show')
      #return
      # Redirect to the show page
      #@followers = followers(@user.screen_name)
      #RAILS_DEFAULT_LOGGER.error "Followers obtained successfully #{@followers.size}"
      # Redirect to the show page
#			render 'posts/show'
#      return
#			respond_to do |format|
#        format.html {
#              @engagement = Engagement.new
#              format.html {  render 'posts/show' }
#        }
#       end
		rescue => err
			# The user might have rejected this application. Or there was some other error during the request.
			RAILS_DEFAULT_LOGGER.error "Failed to get user info via OAuth--" + err
			flash[:error] = "Twitter API failure (account login)"
      if @post && @user
        redirect_to @post.get_url_for(@user,'show')
      else
        redirect_to root_url
      end			
			return
		end
	end

  def get_followers(user_token,user_secret,screen_name)
    twitagent(user_token,user_secret)
    followers(screen_name)
  end
protected
  
    # Inclusion hook to make #current_user, #logged_in? available as ActionView helper methods.
    def self.included(base)
		base.send :helper_method, :current_user, :logged_in? if base.respond_to? :helper_method
    end


    def twitagent( user_token = nil, user_secret = nil )
      #RAILS_DEFAULT_LOGGER.info "twitagent"
      self.twitagent = TwitterOauth.new( user_token, user_secret )  if user_token && user_secret
      self.twitagent = TwitterOauth.new( ) unless @twitagent
      @twitagent ||= raise OauthSystem::NotInitializedError
    end
    def twitagent=(new_agent)
      @twitagent = new_agent || false
    end
	
#    # Accesses the current user from the session.
#    # Future calls avoid the database because nil is not equal to false.
#    def current_user
#		@current_user ||= (login_from_session) unless @current_user == false
#    end
#
#    # Sets the current_user, including initializing the OAuth agent
#    def current_user=(new_user)
#		#RAILS_DEFAULT_LOGGER.info "setting current_user #{new_user.inspect}"
#		if new_user
#			session[:twitter_id] = new_user.twitter_id
#			self.twitagent( user_token = new_user.token, user_secret = new_user.secret )
#			@current_user = new_user
#		else
#			session[:request_token] = session[:request_token_secret] = session[:twitter_id] = nil
#			self.twitagent = false
#			@current_user = false
#		end
#    end
#
#	def oauth_login_required
#		logged_in? || login_by_oauth
#	end
#
#    # Returns true or false if the user is logged in.
#    # Preloads @current_user with the user model if they're logged in.
#    def logged_in?
#		!!current_user
#    end
#
#    def login_from_session
#		self.current_user = Member.find_by_twitter_id(session[:twitter_id]) if session[:twitter_id]
#    end

	def login_by_oauth
		begin
			#RAILS_DEFAULT_LOGGER.info "login_by_oauth"
			request_token = self.twitagent.get_request_token
			session[:request_token] = request_token.token
			session[:request_token_secret] = request_token.secret
      session[:post_id] = params[:post_id] if params[:post_id]
      session[:uid] = params[:uid] if params[:uid]
			# Send to twitter.com to authorize
			# redirect_to request_token.authorize_url
			# return
      @authorization_url = request_token.authorize_url
		rescue
			# The user might have rejected this application. Or there was some other error during the request.
			RAILS_DEFAULT_LOGGER.error "Failed to login via OAuth"
			flash[:error] = "Twitter API failure (account login)"
			redirect_to root_url
			return
		end
	end	

	# controller wrappers for twitter API methods

	# Twitter REST API Method: statuses/update
	def update_status!(  status , in_reply_to_status_id = nil )
		self.twitagent.update_status!(  status , in_reply_to_status_id )
	rescue => err
		# The user might have rejected this application. Or there was some other error during the request.
		RAILS_DEFAULT_LOGGER.error "#{err.message} Failed update status"
		return
	end

	# Twitter REST API Method: statuses friends
	def friends(user=nil)
		self.twitagent.friends(user)
	rescue => err
		RAILS_DEFAULT_LOGGER.error "Failed to get friends via OAuth for #{current_user.inspect}"
		flash[:error] = "Twitter API failure (getting friends)"
		return
	end

	# Twitter REST API Method: statuses followers
	def followers(user=nil)
		self.twitagent.followers(user)
	rescue => err
		RAILS_DEFAULT_LOGGER.error "Failed to get followers via OAuth for #{current_user.inspect}"
		flash[:error] = "Twitter API failure (getting followers)"
		return
	end

	# Twitter REST API Method: statuses mentions
	def mentions( since_id = nil, max_id = nil , count = nil, page = nil )
		self.twitagent.mentions( since_id, max_id, count, page )
	rescue => err
		RAILS_DEFAULT_LOGGER.error "Failed to get mentions via OAuth for #{current_user.inspect}"
		flash[:error] = "Twitter API failure (getting mentions)"
		return
	end

	# Twitter REST API Method: direct_messages
	def direct_messages( since_id = nil, max_id = nil , count = nil, page = nil )
		self.twitagent.direct_messages( since_id, max_id, count, page )
	rescue => err
		RAILS_DEFAULT_LOGGER.error "Failed to get direct_messages via OAuth for #{current_user.inspect}"
		flash[:error] = "Twitter API failure (getting direct_messages)"
		return
	end

  # Twitter REST API Method: direct_messages new
	def send_direct_message!( screen_name, text )
    self.twitagent(@user.token,@user.secret).send_direct_message!( screen_name, text )
	rescue => err
		RAILS_DEFAULT_LOGGER.error "Failed to send direct_messages via OAuth for #{@user.inspect}"
		flash[:error] = "Twitter API failure (sending direct_messages)"
		return
  end
	
end