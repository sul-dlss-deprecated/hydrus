class HydrusMailer < ActionMailer::Base
  default from: "no-reply@hydrus.stanford.edu"
  
  def invitation(opts={})
    @host = setup_host
    @document_fedora = opts[:object]
    mail(:to=>HydrusMailer.process_user_list(opts[:to]), :subject=>"Invitation to deposit in the Stanford Digital Repository") unless protected_druids.include?(@document_fedora.pid)
  end
  
  def object_returned(opts={})
    @host = setup_host
    @document_fedora = opts[:object]
    @returned_by = opts[:returned_by]
    mail(:to=>HydrusMailer.process_user_list(opts[:to]), :subject=>"#{@document_fedora.object_type.capitalize} returned for edits in the Stanford Digital Repository") unless protected_druids.include?(@document_fedora.pid)    
  end
  
  def open_notification(opts={})
    @host = setup_host
    @document_fedora = opts[:object]
    mail(:to=>HydrusMailer.process_user_list(opts[:to]), :subject=>"Collection opened for deposit in the Stanford Digital Repository") unless protected_druids.include?(@document_fedora.pid)
  end
  
  def close_notification(opts={})  
    @host = setup_host
    @document_fedora = opts[:object]
    mail(:to=>HydrusMailer.process_user_list(opts[:to]), :subject=>"Collection closed for deposit in the Stanford Digital Repository") unless protected_druids.include?(@document_fedora.pid)
  end
  
  protected
  
  def setup_host
    case Rails.env
      when 'dortest'
        "hydrus-test.stanford.edu"
      when 'development','test'
        "hydrus-dev.stanford.edu"
      else
        "hydrus.stanford.edu"
    end
  end
  
  def protected_druids
    Hydrus::Application.config.fixture_list
  end
  
  def self.process_user_list(users)
    users.split(",").map do |user|
      user =~ /.+@.+\..+/ ? user.strip : "#{user.strip}@stanford.edu"
    end
  end
end