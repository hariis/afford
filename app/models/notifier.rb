class Notifier < ActionMailer::Base

include ActionView::Helpers::TextHelper
 
default_url_options[:host] = "caniafforditnow.com"

  def password_reset_instructions(user)
    setup_email(user)
    @subject    <<   " Password Reset Instructions"
    recipients    user.email
    body          :edit_password_reset_url => edit_password_reset_url(user.perishable_token)
  end
 
  def account_confirmation_instructions(user)
    setup_email(user)
    @subject    << ' Please activate your new account'
    recipients    user.email
    
    body          :activation_url  => DOMAIN + "activate/#{user.perishable_token}"
  end

  def confirm_activation(user)
    setup_email(user)
    subject    << 'Woohoo! Your account has been activated!'
    body       :url  => DOMAIN
  end

  #bcc           "satish.fnu@gmail.com, satishsisl@yahoo.co.in"
  def notify_on_new_question(question, emails)
    setup_email
    @subject    << 'A new question has been posted'
    recipients    "caniafforditnow@gmail.com" 
    bcc           emails
    body          :question_url  => DOMAIN + "questions/show/#{question.id}", :question => question
  end

  def notify_on_new_response(question, response, emails)
    setup_email
    @subject    << 'A new response has been posted'
    recipients    "caniafforditnow@gmail.com" 
    bcc           emails
    body          :response_url  => DOMAIN + "questions/show/#{question.id}#responses", :question => question,  :response => response
  end

  def send_rules_feedback(description,email)
    setup_email
    @subject    << 'Feedback on Rules Check'
    recipients    "hrajagopal@yahoo.com,satish.fnu@gmail.com"
    body        :description => description, :email => email
  end

  def send_report_feedback(useful,suggestion)
    setup_email
    @subject    << 'Feedback on Expert Report'
    recipients    "hrajagopal@yahoo.com,satish.fnu@gmail.com"
    body        :useful => useful, :suggestion => suggestion
  end
  
  def send_experience(experience)
    setup_email
    @subject    <<   "Feedback | #{experience.feedback_type}"
    recipients    "satish.fnu@gmail.com, hrajagopal@yahoo.com"
    body          :experience => experience
  end
  

  protected
    def setup_email(user=nil)      
      @from        = "Can I Afford It <admin@caniafforditnow.com>"
      headers         "Reply-to" => "caniafforditnow@gmail.com"
      @subject     = ""
      @sent_on     = Time.now
      @content_type = "text/html"
    end
  end
