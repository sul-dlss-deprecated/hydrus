# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def application_name
    'Stanford Digital Repository'
  end

  def catalog_path(*args)
    solr_doc = args.first
    obj_model = solr_doc.get('has_model_s')
    if obj_model.end_with? 'Dor_Collection'
      collection_path(*args)
    elsif obj_model.end_with? 'Dor_Item'
      item_path(*args)
    else
      super
    end
  end

  def catalog_url(*args)
    # TODO: remove duplication.
    solr_doc = args.first
    obj_model = solr_doc.get('has_model_s')
    if obj_model.end_with? 'Dor_Collection'
      collection_url(*args)
    elsif obj_model.end_with? 'Dor_Item'
      item_url(*args)
    else
      super
    end
  end

  # def edit_catalog_path(*args)
  #   solr_doc = args.first
  #   obj_model = solr_doc.get('has_model_s')
  #   if obj_model.end_with? 'Dor_Collection'
  #     edit_collection_path(*args)
  #   elsif obj_model.end_with? 'Dor_Item'
  #     edit_item_path(*args)
  #   else
  #     super
  #   end
  # end

end
