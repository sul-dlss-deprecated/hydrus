class SessionsController < Devise::SessionsController
  layout :set_layout

  before_filter only: [:new] do
    if current_user && params[:referrer]
      redirect_to params[:referrer]
    end
  end

  def set_layout
    request.xhr? ? false : layout_name
  end

  def new
    unless Dor::Config.hydrus.show_standard_login # if we aren't showing standard login, just direct to the webauth login
      redirect_to webauth_login_path(referrer: params[:referrer] || root_url)
      return
    end
    super
  end

  def destroy_webauth
    flash[:notice] = 'You have successfully logged out of WebAuth.' unless request.env['WEBAUTH_USER']
    redirect_to root_url
  end

  def destroy
    super
  end
end
