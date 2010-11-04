class ExperiencesController < ApplicationController

 def capture_experience
    respond_to do |format|
        format.html
        #format.xml { render :xml => @post }
        format.js { render_to_facebox }
    end
 end
 
 def store_experience
     render :update do |page| 
       if params[:feedback_type].to_i == 0
          page.replace_html "experiences-status", "Please select a feedback type"
       elsif params[:description] == "Let us know what you think!"
          page.replace_html "experiences-status", "Please add some details and share again"       
       else
          experience = Experience.new
          experience.feedback_type = Experience::COMMENT_TYPES.index(params[:feedback_type].to_i) if params[:feedback_type]
          experience.description = params[:description]
          experience.email = params[:email] if params[:email]
          Notifier.deliver_send_experience(experience)
          page.visual_effect :blind_up, 'facebox'
       end
     end
 end
end
