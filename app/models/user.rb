class User < ActiveRecord::Base
  has_many :questions, :dependent => :destroy
  has_many :responses, :dependent => :destroy
  has_many :financials, :through => :questions, :dependent => :destroy
  
  acts_as_authentic do |c|
    c.login_field = :username
    c.validate_email_field(false)
  end

  #get all the responses for that user
  def agreed_with_community
    responses = self.responses
    count = 0
    responses.each do |response|
        #count += 1 if response.verdict == response.question.get_community_verdict
        count += 1 if response.question.get_community_verdict(response.verdict)
    end
    return count
  end 
  
  def agreed_with_expert
    responses = self.responses
    count = 0
    responses.each do |response|
        count += 1 if response.verdict == response.question.expert_verdict
    end
    return count
  end
  
  def self.find_by_username_or_email(login)
    User.find_by_username(login) || User.find_by_email(login)
  end
  
  def get_email_name
    begin
    ast = username.index('@')
    name = username[0,ast.to_i]
    return name
    rescue
      RAILS_DEFAULT_LOGGER.error "#{self.id} #{self.username}" + err
    end
    #awesome_truncate(username, username.index('@'), "").capitalize
  end
  
  # Awesome truncate
  # First regex truncates to the length, plus the rest of that word, if any.
  # Second regex removes any trailing whitespace or punctuation (except ;).
  # Unlike the regular truncate method, this avoids the problem with cutting
  # in the middle of an entity ex.: truncate("this &amp; that",9)  => "this &am..."
  # though it will not be the exact length.
  def awesome_truncate(text, length = 30, truncate_string = "...")
    return if text.nil?
    l = length - truncate_string.mb_chars.length
    text.mb_chars.length > length ? text[/\A.{#{l}}\w*\;?/m][/.*[\w\;]/m] + truncate_string : text
  end
end
