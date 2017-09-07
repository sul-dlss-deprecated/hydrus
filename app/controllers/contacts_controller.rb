class ContactsController < ApplicationController
  skip_authorization_check

  before_filter :form_params

  def show
    @page_title = 'Contact Us'
  end

  def create
    if @message.blank?
      flash.now[:error] = 'Please enter message text.'
      render :show
    else
      HydrusMailer.contact_message(params: params, request: request, user: current_user).deliver_now
      flash[:notice] = 'Your message has been sent.'
      if @from.blank?
        redirect_to contact_path
      else
        redirect_to(@from)
      end
    end
  end

  private

  def form_params
    @from = params[:from]
    @subject = params[:subject]
    @name = params[:name]
    @email = params[:email]
    @message = params[:message]
  end
end
