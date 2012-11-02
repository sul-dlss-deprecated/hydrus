class HydrusMailer < ActionMailer::Base
  default from: "no-reply@hydrus.stanford.edu"
    
  def invitation(opts={})
    @document_fedora = opts[:object]
    @collection_url = polymorphic_url(@document_fedora, :host => host)        
    mail(:to=>HydrusMailer.process_user_list(opts[:to]), :subject=>"Invitation to deposit in the Stanford Digital Repository") unless ignore?(@document_fedora.pid)
  end
  
  def object_returned(opts={})
    @document_fedora = opts[:object]
    @returned_by = opts[:returned_by]
    @item_url = opts[:item_url] || polymorphic_url(@document_fedora, :host => host)
    mail(:to=>HydrusMailer.process_user_list(@document_fedora.recipients_for_object_returned_email), :subject=>"#{@document_fedora.object_type.capitalize} returned in the Stanford Digital Repository") unless ignore?(@document_fedora.pid)
  end
  
  def open_notification(opts={})
    @document_fedora = opts[:object]
    @collection_url = polymorphic_url(@document_fedora, :host => host)    
    mail(:to=>HydrusMailer.process_user_list(@document_fedora.recipients_for_collection_update_emails), :subject=>"Collection opened for deposit in the Stanford Digital Repository")  unless ignore?(@document_fedora.pid)
  end
  
  def close_notification(opts={})  
    @document_fedora = opts[:object]
    mail(:to=>HydrusMailer.process_user_list(@document_fedora.recipients_for_collection_update_emails), :subject=>"Collection closed for deposit in the Stanford Digital Repository") unless ignore?(@document_fedora.pid)
  end
  
  protected  
  def ignore?(pid)
    Hydrus::Application.config.fixture_list.include?(pid)
  end
  
  def host 
    Dor::Config.hydrus.host
  end
  
  def self.process_user_list(users)
    users.split(",").map do |user|
      user =~ /.+@.+\..+/ ? user.strip : "#{user.strip}@stanford.edu"
    end
  end
  
end
