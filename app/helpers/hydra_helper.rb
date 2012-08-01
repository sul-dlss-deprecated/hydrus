module HydraHelper

  include Hydra::HydraHelperBehavior

  def home_link
    link_to("Home",root_url)
  end
  
  def edit_and_browse_links
    if params[:action] == "edit" || params[:action] == "update"
      link_to("Switch to browse view", 
              polymorphic_path(@document_fedora, :viewing_context => 'browse'),
              :class => 'browse toggle')
    else
      link_to("Switch to edit view", 
              edit_polymorphic_path(@document_fedora, :viewing_context => 'edit'),
              :class => 'edit toggle')
    end
  end

end
