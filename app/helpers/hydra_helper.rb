module HydraHelper

  include Hydra::HydraHelperBehavior

  def edit_and_browse_links
    if params[:action] == "edit"
      link_to( 
        "Switch to browse view", 
        polymorphic_path(@document_fedora, :viewing_context => 'browse'),
        :class => 'browse toggle'
      )
    else
      link_to( 
        "Switch to edit view", 
        edit_polymorphic_path(@document_fedora, :viewing_context => 'edit'),
        :class => 'edit toggle'
      )
    end
  end

end
