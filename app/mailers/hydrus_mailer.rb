class HydrusMailer < ActionMailer::Base
  default from: "no-reply@hydrus.stanford.edu"
  
  def invitation(opts={})
    @document_fedora = opts[:object]
    mail(:to=>HydrusMailer.process_user_list(opts[:to]), :subject=>"Invitation to deposit in the Stanford Digital Repository") unless protected_druids.include?(@document_fedora.pid)
  end
  
  def open_notification(opts={})
    @document_fedora = opts[:object]
    mail(:to=>HydrusMailer.process_user_list(opts[:to]), :subject=>"Collection opened for deposit in the Stanford Digital Repository") unless protected_druids.include?(@document_fedora.pid)
  end
  
  def close_notification(opts={})  
    @document_fedora = opts[:object]
    mail(:to=>HydrusMailer.process_user_list(opts[:to]), :subject=>"Collection closed for deposit in the Stanford Digital Repository") unless protected_druids.include?(@document_fedora.pid)
  end
  
  protected
  
  def protected_druids
    Hydrus::Application.config.fixture_list
  end
  
  def self.process_user_list(users)
    users.split(",").map do |user|
      user =~ /.+@.+\..+/ ? user.strip : "#{user.strip}@stanford.edu"
    end
  end
end