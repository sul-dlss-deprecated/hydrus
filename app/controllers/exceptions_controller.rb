class ExceptionsController < ApplicationController
  
  skip_authorization_check
  
  def render_404
    @exception = env['action_dispatch.exception']
    @status_code = ActionDispatch::ExceptionWrapper.new(env, @exception).status_code
    render '404', status: @status_code, layout: true
  end
  
  def render_500
    @exception = env['action_dispatch.exception']
    @status_code = ActionDispatch::ExceptionWrapper.new(env, @exception).status_code
    render '500', status: @status_code, layout: true
  end
end
