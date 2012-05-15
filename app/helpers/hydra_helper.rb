module HydraHelper
  include Hydra::HydraHelperBehavior

  def edit_and_browse_links
    if params[:action] == "edit"
      result = "<a href=\"#{catalog_path(@pid, :viewing_context=>"browse")}\" class=\"browse toggle\">Switch to browse view</a>"
    else
      result = "<a href=\"#{edit_catalog_path(@pid, :viewing_context=>"edit")}\" class=\"edit toggle\">Switch to edit view</a>"
    end
    return result.html_safe
  end

end

