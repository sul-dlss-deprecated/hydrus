###
#  Simple controller to handle login and redirect
###
class LoginController < ApplicationController
  skip_authorization_check only: :login

  def login
    if params[:referrer].present?
      redirect_to params[:referrer]
    else
      redirect_back fallback_location: root_url
    end
  end
end
