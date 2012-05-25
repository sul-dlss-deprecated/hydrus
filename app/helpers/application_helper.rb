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
  
  # used to determine if we should show beta message in UI
  def is_production?
    return true if Rails.env.production? and (!request.env["HTTP_HOST"].nil? and !request.env["HTTP_HOST"].include?("-test") and !request.env["HTTP_HOST"].include?("-dev") and !request.env["HTTP_HOST"].include?("localhost"))
  end

  def render_head_content
    render_extra_head_content +
    content_for(:head)
  end

end
