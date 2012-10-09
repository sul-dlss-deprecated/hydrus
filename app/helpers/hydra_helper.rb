module HydraHelper

  include Hydra::HydraHelperBehavior

  # indicates if we should show the item edit tab for a given item
  # only if its not published yet, unless we are in development mode (to make development easier)
  def show_item_edit(item)
    can?(:edit,@document_fedora) && (!@document_fedora.is_published || ["development","test"].include?(Rails.env))
  end
  
  def edit_item_text(item)
    ["development","test"].include?(Rails.env) ? "Edit Draft (only for dev)" : "Edit Draft"
  end
  
  # text to show on item view tab
  def view_item_text(item)
    item.is_published ? "Published Version" : "View Draft"
  end

end
