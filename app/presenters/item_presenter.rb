# Displays an item on the collections table
class ItemPresenter
  # @param [SolrDocument] solr_doc a hash representing the object in solr
  def initialize(solr_doc:, num_files:)
    @solr_doc = solr_doc
    @num_files = num_files
  end

  attr_reader :solr_doc, :num_files

  def pid
    solr_doc['id']
  end

  def title
    solr_doc.object_title
  end

  def status
    array_to_single(solr_doc['object_status_ssim'])
  end

  def object_type
    array_to_single(solr_doc['mods_typeOfResource_ssim'])
  end

  def depositor
    array_to_single(solr_doc['item_depositor_person_identifier_ssm'])
  end

  def create_date
    solr_doc['system_create_dtsi']
  end

  private

  # given a solr doc field that might be an array, extract the first value if not nil, otherwise return blank
  def array_to_single(solr_doc_value)
    solr_doc_value.blank? ? '' : solr_doc_value.first
  end
end
