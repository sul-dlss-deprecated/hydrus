module ApplicationHelper
  include HydrusFormHelper
  
  def application_name
    'Stanford Digital Repository'
  end
  
  def seen_beta_dialog?
    if session[:seen_beta_dialog]
      return true
    else
      session[:seen_beta_dialog]=true
      return false
    end
  end

  def render_head_content
    render_extra_head_content +
    content_for(:head)
  end

end
