# A mixin for running SOLR queries.

module Hydrus::SolrQueryable

  # Convenience variable to execute module methods.
  HSQ = self

  ####
  # Module methods that modify the SOLR query parameters hash.
  ####

  # Takes a hash of SOLR query parameters, along with a SUNET ID.
  # Adds a condition to the filter query parameter requiring that
  # the user's ID be present in the object's role metadata.
  # If opt[:or] is true, this condition will be OR'd with the
  # preceding condition in the :fq array.
  def self.add_involved_user_filter(h, user, opt = {})
    return unless user
    s = %Q<roleMetadata_role_person_identifier_t:"#{user}">
    h[:fq] ||= []
    if opt[:or]
      if h[:fq].size == 0
        h[:fq][0] = s
      else
        h[:fq][-1] += " OR #{s}"
      end
    else
      h[:fq] << s
    end
  end

  # Takes a hash of SOLR query parameters, along with an array of APO druids.
  # Adds a condition to the filter query parameter requiring that
  # the objects be governed by the given APOs.
  def self.add_governed_by_filter(h, druids)
    return unless druids.size > 0
    h[:fq] ||= []
    igb = druids.map { |d| %Q<"info:fedora/#{d}"> }.join(' OR ')
    h[:fq] << %Q<is_governed_by_s:(#{igb})>
  end

  # Takes a hash of SOLR query parameters, along with some model names.
  # Adds a condition to the filter query parameter requiring that
  # the objects have models of one of the specified types.
  def self.add_model_filter(h, *models)
    return unless models.size > 0
    h[:fq] ||= []
    hms = models.map { |m| %Q<"info:fedora/afmodel:#{m}"> }.join(' OR ')
    h[:fq] << %Q<has_model_s:(#{hms})>
  end

  ####
  # Instance methods to issue SOLR queries or generate SOLR query hashes.
  ####

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
    h = {
      :rows => 9999,
      :fl   => 'identityMetadata_objectId_t',
      :q    => '*',
    }
    HSQ.add_model_filter(h, 'Hydrus_AdminPolicyObject')
    HSQ.add_involved_user_filter(h, user)
    return h
  end

  # Takes an array of APO druids.
  # Returns a hash of SOLR query parameters.
  # The query: get the Collections governed by the APOs.
  def squery_collections_of_apos(druids)
    h = {
      :rows => 9999,
      :fl   => 'identityMetadata_objectId_t',
      :q    => '*',
    }
    HSQ.add_model_filter(h, 'Hydrus_Collection')
    HSQ.add_governed_by_filter(h, druids)
    return h
  end

  # Takes an array of Collection druids.
  # Returns a hash of SOLR query parameters.
  # The query: get Item counts-by-status for those Collections.
  def squery_item_counts_of_collections(druids)
    imo = druids.map { |d| %Q<"info:fedora/#{d}"> }.join(' OR ')
    h = {
      :rows          => 0,
      :fl            => '',
      :facet         => true,
      :'facet.pivot' => 'is_member_of_s,object_status_facet',
      :q             => '*',
      :fq            => [ %Q<is_member_of_s:(#{imo})> ],
    }
    HSQ.add_model_filter(h, 'Hydrus_Item')
    return h
  end

end
