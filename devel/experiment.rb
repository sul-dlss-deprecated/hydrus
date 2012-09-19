def dashboard(*args)

  # Current logged in user.
  user = args.first

  # Get PIDs of the APOs where USER plays a role.
  # Start building up a hash keyed by the APO pid.
  resp, sdocs = run_solr_query('apos', user)
  info = {}
  resp.docs.each do |doc|
    apo_pid = doc['identityMetadata_objectId_t'].first
    info[apo_pid] = {
      :user    => user,
      :apo_pid => apo_pid,
      :roles   => doc["roles_of_sunetid_#{user}_t"],
    }
  end

  # Get PIDs of the Collections governed by those APOs.
  # Add those PIDs to the info hash.
  # Also create a hash connecting Collection and APO pids.
  resp, sdocs = run_solr_query('colls', *info.keys)
  c2a = {}
  resp.docs.each do |doc|
    apo_pid  = doc['is_governed_by_s'].first.sub(/.+\/druid/, 'druid')
    coll_pid = doc['identityMetadata_objectId_t'].first
    info[apo_pid][:coll_pid] = coll_pid
    c2a[coll_pid] = apo_pid
  end

  # Get counts of Items-by-workflow-status for those Collections.
  # Add those counts to the info hash.
  resp, sdocs = run_solr_query('stats', *c2a.keys)
  resp.facet_counts['facet_pivot'].values.first.each { |h|
    coll_pid = h['value'].sub(/.+\/druid/, 'druid')
    apo_pid  = c2a[coll_pid]
    h['pivot'].each { |p|
      status = p['value']
      n      = p['count']
      info[apo_pid][:item_counts] ||= {}
      info[apo_pid][:item_counts][status] = n
    }
  }

  ap info

end

def run_solr_query(*args)

  # Get the APO (druids) for which USER has a role.
  if args.first == 'apos'
    user = args[1]
    h = {
      :q => [
        'has_model_s:"info:fedora/afmodel:Hydrus_AdminPolicyObject"',
        'roleMetadata_role_person_identifier_t:' + user,
      ].join(' AND '),
      :fl => [
        'identityMetadata_objectId_t',
        "roles_of_sunetid_#{user}_t",
      ].join(','),
      :rows => 9999,
    }

  # Get Collections (druids and titles) that are governed by those APOs.
  elsif args.first == 'colls'
    args.shift
    druids = args.map { |d| "info:fedora/#{d}".gsub(/([:\/])/, '\\\\\1') }
    igb = druids.join(' OR ')
    h = {
      :q => [
        'has_model_s:"info:fedora/afmodel:Hydrus_Collection"',
        "is_governed_by_s:(#{igb})"
      ].join(' AND '),
      :fl => [
        'identityMetadata_objectId_t',
        'is_governed_by_s',
      ].join(','),
      :rows => 9999,
    }

  # Get Item counts-by-status for those Collections.
  elsif args.first == 'stats'
    args.shift
    imo = args.map { |d| %Q<"info:fedora/#{d}"> }.join(' OR ')
    h = {
      :q => [
        'has_model_s:"info:fedora/afmodel:Hydrus_Item"',
        "is_member_of_s:(#{imo})"
      ].join(' AND '),
      :fl => [
        'is_member_of_s',
        'hydrus_wf_status_t',
        'identityMetadata_objectId_t',
      ].join(','),
      :facet => true,
      :'facet.pivot' => 'is_member_of_s,hydrus_wf_status_facet',
      :rows => 0,
    }

  elsif args.first == 'resp'
    h = {
      :q    => '*.*',
      :fl   => 'identityMetadata_objectId_t',
    }

  else
    h = {
      :q    => '*.*',
      :fl   => 'identityMetadata_objectId_t',
    }
  end

  solr_response = Blacklight.solr.find(h)
  document_list = solr_response.docs.map {|doc| SolrDocument.new(doc, solr_response)}  
  return [solr_response, document_list]
end

def solr_query(*args)
  resp, sdocs = run_solr_query(*args)
  ap resp['response']['numFound']
  ap resp
end

def resolrize(*args)
  pid = args.first
  solrizer = Solrizer::Fedora::Solrizer.new(:index_full_text => true)
  if pid
    pid = "druid:#{pid}"
    solrizer.solrize(pid)
  else
    solrizer.solrize_objects(:suppress_errors => true)
  end
end

method(ARGV.shift).call(*ARGV)
