class HydrusMailer < ActionMailer::Base
  helper ApplicationHelper

  default from: 'no-reply@sdr.stanford.edu'

  def contact_message(opts = {})
    params = opts[:params]
    @request = opts[:request]
    @message = params[:message]
    @email = params[:email]
    @name = params[:name]
    @subject = params[:subject]
    @from = params[:from]
    @user = opts[:user]
    to = Hydrus::Application.config.contact_us_recipients[@subject]
    cc = Hydrus::Application.config.contact_us_cc_recipients[@subject]
    mail(to: to, cc: cc, subject: "Contacting the Stanford Digital Repository (SDR) - #{@subject}")
  end

  def invitation(opts = {})
    @fobj = opts[:object]
    @collection_url = root_url(host: host)
    mail(to: HydrusMailer.process_user_list(opts[:to]), subject: 'Invitation to deposit in the Stanford Digital Repository') unless ignore?(@fobj.pid)
  end

  def invitation_removed(opts = {})
    @fobj = opts[:object]
    @collection_url = polymorphic_url(@fobj, host: host)
    mail(to: HydrusMailer.process_user_list(opts[:to]), subject: 'Removed as a depositor in the Stanford Digital Repository') unless ignore?(@fobj.pid)
  end

  def role_change(opts = {})
    @fobj = opts[:object]
    @collection_url = polymorphic_url(@fobj, host: host)
    mail(to: HydrusMailer.process_user_list(opts[:to]), subject: 'Collection member updates in the Stanford Digital Repository') unless ignore?(@fobj.pid)
  end

  def object_returned(opts = {})
    @fobj = opts[:object]
    @returned_by = opts[:returned_by]
    @item_url = opts[:item_url] || polymorphic_url(@fobj, host: host)
    mail(to: HydrusMailer.process_user_list(@fobj.recipients_for_object_returned_email), subject: "#{@fobj.object_type.capitalize} returned in the Stanford Digital Repository") unless ignore?(@fobj.pid)
  end

  def item_deposit(opts = {})
    @fobj = opts[:object]
    @item_url = opts[:item_url] || polymorphic_url(@fobj, host: host)
    mail(to: HydrusMailer.process_user_list(@fobj.recipients_for_item_deposit_emails), subject: "#{@fobj.object_type.capitalize} deposited in the Stanford Digital Repository") unless ignore?(@fobj.pid)
  end

  def new_deposit(opts = {})
    @fobj = opts[:object]
    @item_url = opts[:item_url] || polymorphic_url(@fobj, host: host)
    mail(to: HydrusMailer.process_user_list(@fobj.recipients_for_new_deposit_emails), subject: "Draft #{@fobj.object_type.capitalize} created in the Stanford Digital Repository") unless ignore?(@fobj.pid)
  end

  def new_item_for_review(opts = {})
    @fobj = opts[:object]
    @item_url = opts[:item_url] || polymorphic_url(@fobj, host: host)
    mail(to: HydrusMailer.process_user_list(@fobj.recipients_for_review_deposit_emails), subject: "#{@fobj.object_type.capitalize} ready for review in the Stanford Digital Repository") unless ignore?(@fobj.pid)
  end

  def open_notification(opts = {})
    @fobj = opts[:object]
    @collection_url = root_url(host: host)
    mail(to: HydrusMailer.process_user_list(@fobj.recipients_for_collection_update_emails), subject: 'Collection opened for deposit in the Stanford Digital Repository') unless ignore?(@fobj.pid)
  end

  def close_notification(opts = {})
    @fobj = opts[:object]
    mail(to: HydrusMailer.process_user_list(@fobj.recipients_for_collection_update_emails), subject: 'Collection closed for deposit in the Stanford Digital Repository') unless ignore?(@fobj.pid)
  end

  def send_purl(opts = {})
    @current_user = opts[:current_user]
    @fobj = opts[:object]
    mail(to: opts[:recipients], subject: 'PURL page shared from the Stanford Digital Repository')
  end

  protected

  def ignore?(pid)
    Hydrus.fixture_pids.include?(pid)
  end

  def host
    Dor::Config.hydrus.host
  end

  def self.process_user_list(users)
    users.split(',').map do |user|
      user.match?(/.+@.+\..+/) ? user.strip : "#{user.strip}@stanford.edu"
    end
  end
end
