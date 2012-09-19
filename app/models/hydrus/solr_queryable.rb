# A mixin for running SOLR queries.

module Hydrus::SolrQueryable

  # Takes a hash of parameters for a SOLR query.
  # Runs the query an returns a two-element array containing the SOLR
  # response and an array of SolrDocuments.
  def issue_solr_query(h)
    solr_response = Blacklight.solr.find(h)
    document_list = solr_response.docs.map {|doc| SolrDocument.new(doc, solr_response)}  
    return [solr_response, document_list]
  end

  # Takes a string -- a user's SUNET ID.
  # Returns a hash of SOLR query parameters.
  # The query: get the APOs for which USER has a role.
  def squery_apos_involving_user(user)
    return {
      :rows => 9999,
      :fl   => 'identityMetadata_objectId_t',
      :q    => [
        %Q<has_model_s:"info:fedora/afmodel:Hydrus_AdminPolicyObject">,
        %Q<roleMetadata_role_person_identifier_t:"#{user}">,
      ].join(' AND '),
    }
  end

  # Takes an array of APO druids.
  # Returns a hash of SOLR query parameters.
  # The query: get the Collections governed by the APOs.
  def squery_collections_of_apos(druids)
    igb = druids.map { |d| %Q<"info:fedora/#{d}"> }.join(' OR ')
    return {
      :rows => 9999,
      :fl   => 'identityMetadata_objectId_t',
      :q    => [
        %Q<has_model_s:"info:fedora/afmodel:Hydrus_Collection">,
        %Q<is_governed_by_s:(#{igb})>
      ].join(' AND '),
    }
  end

  # Takes an array of Collection druids.
  # Returns a hash of SOLR query parameters.
  # The query: get Item counts-by-status for those Collections.
  def squery_item_counts_of_collections(druids)
    imo = druids.map { |d| %Q<"info:fedora/#{d}"> }.join(' OR ')
    return {
      :rows          => 0,
      :fl            => '',
      :facet         => true,
      :'facet.pivot' => 'is_member_of_s,hydrus_wf_status_facet',
      :q => [
        %Q<has_model_s:"info:fedora/afmodel:Hydrus_Item">,
        %Q<is_member_of_s:(#{imo})>,
      ].join(' AND '),
    }
  end

end
