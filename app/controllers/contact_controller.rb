class ContactController < ApplicationController
  skip_authorization_check

  def index
    @page_title = 'Contact Us'
    @from = params[:from]
    @subject = params[:subject]
    @name = params[:name]
    @email = params[:email]
    @message = params[:message]

    return unless request.post?

    if @message.blank?
      flash.now[:error] = 'Please enter message text.'
    else
      HydrusMailer.contact_message(params: params, request: request, user: current_user).deliver_now
      flash[:notice] = 'Your message has been sent.'
      @message = nil
      @name = nil
      @email = nil
      unless @from.blank?
        redirect_to(@from)
        return
      end
    end
  end
end
