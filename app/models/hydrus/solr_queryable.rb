# A mixin for running SOLR queries.

module Hydrus::SolrQueryable

  # Convenience variable to execute module methods.
  HSQ = self

  ####
  # Module methods that modify the SOLR query parameters hash.
  ####

  def self.add_gated_discovery(solr_parameters, apo_pids, user)

    h = { :fq => []}
    add_governed_by_filter(h, apo_pids)
    add_involved_user_filter(h, user)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << h[:fq].join(" OR ") unless h[:fq].empty?
  end

  # Takes a hash of SOLR query parameters, along with a SUNET ID.
  # Adds a condition to the filter query parameter requiring that
  # the user's ID be present in the object's role metadata.
  # If opt[:or] is true, this condition will be OR'd with the
  # preceding condition in the :fq array.
  def self.add_involved_user_filter(h, user, opt = {})
    return unless user
    s = %Q<roleMetadata_role_person_identifier_facet:"#{user}">
    h[:fq] ||= []
    h[:fq] << s
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
    h[:fq] << %Q<has_model_ssim:(#{hms})>
  end

  # Returns a default hash of query params, used by a few methods.
  def self.default_query_params
    return {
      :rows => 9999,
      :fl   => 'identityMetadata_objectId_t',
      :q    => '*',
    }
  end

  ####
  # Instance methods to issue SOLR queries or generate SOLR query hashes.
  ####

  # Takes a hash of parameters for a SOLR query.
  # Runs the query an returns a two-element array containing the SOLR
  # response and an array of SolrDocuments.
  def issue_solr_query(*args)
    Hydrus::SolrQueryable.issue_solr_query *args
  end
  #This static version was added specifically to deal with loading the dashboard without instantiating an object. 
  def self.issue_solr_query(h)
    solr_response = solr.select(params: h)
    document_list = solr_response['response']['docs'].map {|doc| SolrDocument.new(doc, solr_response)}
    return [solr_response, document_list]
  end
  
  def self.solr
      @solr ||= RSolr.connect(Blacklight.solr_config)
  end

  # Returns a hash of SOLR query parameters.
  # The query: get all Hydrus APOs, Collections, and Items.
  def squery_all_hydrus_objects(models, opts = {})
    h = HSQ.default_query_params()
    h[:fl] = opts[:fields].join(',') if opts[:fields]
    HSQ.add_model_filter(h, *models)
    return h
  end

  # Returns a hash of SOLR query parameters.
  # The query: get all Hydrus Collections.
  def squery_all_hydrus_collections
    return squery_all_hydrus_objects(['Hydrus_Collection'],:fields=>['*'])
  end

  # Returns a hash of SOLR query parameters.
  # The query: get all Hydrus Collections.
  def squery_all_hydrus_apos
    return squery_all_hydrus_objects(['Hydrus_AdminPolicyObject'])
  end
  
  # Takes a string -- a user's SUNET ID.
  # Returns a hash of SOLR query parameters.
  # The query: get the APOs for which USER has a role.
  def squery_apos_involving_user(user)
    h = HSQ.default_query_params()
    HSQ.add_model_filter(h, 'Hydrus_AdminPolicyObject')
    HSQ.add_involved_user_filter(h, user)
    return h
  end
  
  def squery_apo_roles(apo_druid)
    
  end
  
  
  # Takes an array of APO druids.
  # Returns a hash of SOLR query parameters.
  # The query: get the Collections governed by the APOs.
  def squery_collections_of_apos(druids)
    h = HSQ.default_query_params()
    h[:fl]='*'
    HSQ.add_model_filter(h, 'Hydrus_Collection')
    HSQ.add_governed_by_filter(h, druids)
    return h
  end

  # Takes the druid of a collection, returns solr documents for all items in that collection
  def squery_items_in_collection(druid)
    imo = %Q<"info:fedora/#{druid}">
    h = {
      :rows          => 1000,
      :fl            => '',
      :facet         => false,
      :q             => '*',
      :fq            => [ %Q<is_member_of_collection_ssim:(#{imo})> ],
    }
    HSQ.add_model_filter(h, 'Hydrus_Item')
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
      :'facet.pivot' => 'is_member_of_collection_ssim,object_status_facet',
      :q             => '*',
      :fq            => [ %Q<is_member_of_collection_ssim:(#{imo})> ],
    }
    HSQ.add_model_filter(h, 'Hydrus_Item')
    return h
  end

  # Returns an array of druids for all objects belonging to the
  # requested models -- by default Hydrus APOs, Collections, and Items.
  def all_hydrus_objects(opts = {})
    # Get the requested models, in stringified form ready for SOLR query.
    models = opts[:models] || [
      Hydrus::AdminPolicyObject,
      Hydrus::Collection,
      Hydrus::Item,
    ]
    models = models.map { |m| m.to_s.gsub(/::/, '_') }
    # Define SOLR query with the desired fields.
    fields = {
      'identityMetadata_objectId_t' => :pid,
      'has_model_ssim'                 => :object_type,
      'object_version_t'            => :object_version,
    }
    h = squery_all_hydrus_objects(models, :fields => fields.keys)
    # Run query and return either a list of PIDs if that's all the caller wanted.
    resp, sdocs = issue_solr_query(h)
    return get_druids_from_response(resp) if opts[:pids_only]
    # Otherwise, return a list of hashes. Each hash corresponds
    # to a SOLR doc, and its keys are the fields.values defined above.
    # In addition, simplify the :object_type values to be "Item", "Collection",
    # or "AdminPolicyObject".
    data = get_fields_from_response(resp, fields)
    data.each do |d|
      d[:object_type] = d[:object_type].sub(/\Ainfo:fedora\/afmodel:Hydrus_/, '')
    end
    return data
  end

  # Takes a SOLR response.
  # Returns an array of druids corresponding to the documents.
  def get_druids_from_response(resp)
    k = 'identityMetadata_objectId_t'
    return resp.docs.map { |doc| doc[k].first }
  end

  # Takes a SOLR response and a hash of field remappings.
  # Returns an array of hashes corresponding to the documents.
  # The fields hash defines a mapping between the keys used to
  # retrieve values from the SOLR documents and the keys used to
  # store those values in the returned array-of-hashes. See the
  # all_hydrus_objects() method for an example fields hash.
  # When retrieving values from the SOLR documents, only the first
  # values for each key is retained.
  def get_fields_from_response(resp, fields)
    return resp.docs.map { |doc|
      h = {}
      fields.each { |solr_doc_key, remapped_key|
        d = doc[solr_doc_key]
        val = d ? d.first : nil
        h[remapped_key] = val
      }
      h
    }
  end

end
