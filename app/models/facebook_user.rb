class FacebookUser < ActiveRecord::Base
  def self.create_from_fb(access_token,user_id)
    atts = JSON.parse(access_token.get('/me'))
    atts['facebook_id'] = atts.delete('id')
    returning(first(:conditions => { :facebook_id => atts['facebook_id'] }) || create(atts.slice(*column_names))) do |user|
      user.update_attributes(:token => access_token.token, :user_id => user_id)
    end
  end
  
  # Write to the user's stream
  def post(message)
    OAuth2::AccessToken.new(OAuthClient, token).post('/me/feed', :message => message)
  end
end
