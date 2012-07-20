class SigninController < ApplicationController
  
  def new
    
  end
  
  def login
    redirect_to params[:referrer]
  end
  
  def logout
    flash[:notice] = "You have successfully logged out of WebAuth." unless request.env["WEBAUTH_USER"]
    redirect_to :back
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