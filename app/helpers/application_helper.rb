module ApplicationHelper
  include HydrusFormHelper
  def application_name
    'Stanford Digital Repository'
  end

  def render_head_content
    render_extra_head_content +
    content_for(:head)
  end

end
