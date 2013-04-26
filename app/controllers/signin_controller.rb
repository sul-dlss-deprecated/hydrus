class SigninController < ApplicationController

  def new
    redirect_to root_url and return if current_user # send users to the home page if they are already logged in

    unless Dor::Config.hydrus.show_standard_login # if we aren't showing standard login, just direct to the webauth login
      redirect_to webauth_login_path(:referrer => params[:referrer] || root_url)
      return
    end
    
    respond_to do |format|
      format.html
      format.js
    end
    
  end

  def login
    redirect_to params[:referrer] || root_url
  end

  def logout
    flash[:notice] = "You have successfully logged out of WebAuth." unless request.env["WEBAUTH_USER"]
    redirect_to root_url
  end

  protected
  def resource_name
    :user
  end

  def resource
    @resource ||= User.new
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end

  helper_method :resource
  helper_method :resource_name
  helper_method :devise_mapping

end