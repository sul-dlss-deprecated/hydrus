class HydrusMailer < ActionMailer::Base

  helper ApplicationHelper

  default from: "no-reply@hydrus.stanford.edu"

  def invitation(opts={})
    @fobj = opts[:object]
    @collection_url = polymorphic_url(@fobj, :host => host)
    mail(:to=>HydrusMailer.process_user_list(opts[:to]), :subject=>"Invitation to deposit in the Stanford Digital Repository") unless ignore?(@fobj.pid)
  end

  def object_returned(opts={})
    @fobj = opts[:object]
    @returned_by = opts[:returned_by]
    @item_url = opts[:item_url] || polymorphic_url(@fobj, :host => host)
    mail(:to=>HydrusMailer.process_user_list(@fobj.recipients_for_object_returned_email), :subject=>"#{@fobj.object_type.capitalize} returned in the Stanford Digital Repository") unless ignore?(@fobj.pid)
  end

  def open_notification(opts={})
    @fobj = opts[:object]
    @collection_url = polymorphic_url(@fobj, :host => host)
    mail(:to=>HydrusMailer.process_user_list(@fobj.recipients_for_collection_update_emails), :subject=>"Collection opened for deposit in the Stanford Digital Repository")  unless ignore?(@fobj.pid)
  end

  def close_notification(opts={})
    @fobj = opts[:object]
    mail(:to=>HydrusMailer.process_user_list(@fobj.recipients_for_collection_update_emails), :subject=>"Collection closed for deposit in the Stanford Digital Repository") unless ignore?(@fobj.pid)
  end

  def send_purl(opts={})
    @current_user=opts[:current_user]
    @fobj = opts[:object]
    mail(:to=>opts[:recipients], :subject=>"PURL page shared from the Stanford Digital Repository")
  end

  def error_notification(opts={})
    @exception=opts[:exception]
    @host=host
    @mode=Rails.env
    @current_user=opts[:current_user]
    mail(:to=>Dor::Config.hydrus.exception_recipients, :subject=>"Hydrus Exception Notification from #{@host} running in #{@mode} mode")
  end

  protected

  def ignore?(pid)
    Hydrus.fixture_pids.include?(pid)
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
