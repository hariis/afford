class Response < ActiveRecord::Base
  belongs_to :question
  belongs_to :user
  
  #after_create :new_response_notification
  
  def new_response_notification    
    notify_users = Notification.find(:all, :conditions => ['question_id = ?', self.question_id])
    emails = ""
    notify_users.each do |user|
      emails << user.email
      emails << ","
    end
    Notifier.deliver_notify_on_new_response(self.question, self, emails.chop)
  end
  
end
