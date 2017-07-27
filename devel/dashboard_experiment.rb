def dashboard(*args)
  # Controller: get the stats.
  user  = args.first
  stats = Hydrus::Collection.dashboard_stats(user)
  # Controller: add the stats to the collections.
  collections = stats.keys.map { |coll_dru|
    hc  = Hydrus::Collection.find(coll_dru)
    hc.item_counts = stats[hc.pid] || {}
    hc
  }
  # View: display results.
  collections.each do |hc|
    ap({
      :coll_pid    => hc.pid,
      :apo_pid     => hc.apo.pid,
      :title       => hc.title,
      :roles       => hc.apo.roles_of_person(user),
      :item_counts => hc.item_counts,
    })
  end
end

def solr_query(*args)
  h = {
    :q    => '*.*',
    :fl   => 'objectId_ssim',
  }
  resp, sdocs = issue_solr_query(h)
  ap resp['response']['numFound']
  # ap resp
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
