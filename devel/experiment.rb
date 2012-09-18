def dashboard(*args)

  # Current logged in user.
  user = args.first

  # Get PIDs of the APOs where USER plays a role.
  resp, sdocs = run_solr_query('apos', user)
  apo_druids = resp.docs.map { |d| d['identityMetadata_objectId_t'].first }

  # Get PIDs of the Collections governed by those APOs.
  resp, sdocs = run_solr_query('colls', *apo_druids)
  coll_druids = resp.docs.map { |d| d['identityMetadata_objectId_t'].first }

  # Get counts of Items-by-workflow-status for those Collections.
  resp, sdocs = run_solr_query('stats', *coll_druids)
  stats = {}
  resp.facet_counts['facet_pivot'].values.first.each { |h|
    druid = h['value'].sub(/.+\/druid/, 'druid')
    h['pivot'].each { |p|
      status = p['value']
      n      = p['count']
      stats[druid] ||= {}
      stats[druid][status] = n
    }
  }

  # Pull all of the information together.
  colls = {}
  coll_druids.each do |coll_dru|
    hc  = Hydrus::Collection.find(coll_dru)
    apo = hc.apo
    ap({
      :pid         => hc.pid,
      :apo_pid     => apo.pid,
      :title       => hc.title,
      :roles       => apo.roles_of_person(user),
      :item_counts => stats[hc.pid] || {},
    })
  end

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
