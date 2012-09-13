# module Dor
#   class WorkflowDs < ActiveFedora::NokogiriDatastream 
#     def to_solr(solr_doc = {}, *args)
#       puts "to_solr()"
#       super(solr_doc, *args)
#     end
#   end
# end
  
def noko_doc(x)
  Nokogiri.XML(x) { |conf| conf.default_xml.noblanks }
end

def role_md
  rmd_start = '<roleMetadata>'
  rmd_end   = '</roleMetadata>'
  xml = <<-EOF
    #{rmd_start}
      <role type="hydrus-collection-manager">
         <person>
            <identifier type="sunetid">brown</identifier>
            <name>Brown, Malcolm</name>
         </person>
         <person>
            <identifier type="sunetid">dblack</identifier>
            <name>Black, Delores</name>
         </person>
      </role>
      <role type="hydrus-collection-depositor">
         <person>
            <identifier type="sunetid">ggreen</identifier>
            <name>Green, Greg</name>
         </person>
      </role>
      <role type="hydrus-collection-reviewer">
         <person>
            <identifier type="sunetid">bblue</identifier>
            <name>Blue, Bill</name>
         </person>
      </role>
    #{rmd_end}
  EOF
  return Hydrus::RoleMetadataDS.from_xml(noko_doc(xml))
end

def run_solr_query(user)

  # :q  :rows :fq
  h = {
    :q => [
      'has_model_s:info\:fedora/afmodel\:Hydrus_Collection',
      # 'wf_wps_facet:hydrusAssemblyWF\:start-deposit\:completed',
    ].join(' AND '),
    # :q    => '*:*',
    # :q => [
    #   'has_model_s:info\:fedora/afmodel\:Hydrus_Item',
    #   'is_governed_by_s:(info\:fedora/druid\:oo000oo0009 OR info\:fedora/druid\:oo000oo0002)',
    #   # 'wf_wps_facet:hydrusAssemblyWF\:start-deposit\:completed',
    # ].join(' AND '),
    # :q    => 'has_model_s:info\:fedora/afmodel\:Hydrus_Item AND ' +
    #            'abstract_t:research',
    # :rows => 100,
    # :fq => [
    #   # 'has_model_s:info\:fedora/afmodel\:Hydrus_Collection',
    #   'wf_wps_facet:(hydrusAssemblyWF\:start-deposit\:completed) NOT ' +
    #                 'hydrusAssemblyWF\:submit\:foo',
    # ],
    # :fq => [
    #   'has_model_s:info\:fedora/afmodel\:Hydrus_Item',
    #   'is_governed_by_s:info\:fedora/druid\:oo000oo0009',
    #   # 'wf_wps_facet:hydrusAssemblyWF\:start-deposit\:completed',
    # ].join(' AND '),
    :fl => [
      # 'has_model_s',
      # 'is_governed_by_s',
      # 'wf_wps_facet',
      'identityMetadata_objectId_t',
      # 'abstract_t',
      # 'wf_wps_facet:hydrusAssemblyWF\:start-deposit\:completed',
      # 'wf_wps_facet:hydrusAssemblyWF\:submit\:completed',
    ].join(','),
    :facet => true,
    :'facet.field' => 'wf_wps_facet',
    # :'facet.pivot' => 'is_governed_by_s',
    # :'facet.field' => 'wf_wps_facet',
    # :group => true,
    # :'group.field' => 'is_governed_by_s',
  }

    # :fq => [
    #   'has_model_s:info\:fedora/afmodel\:Hydrus_Collection',
    #   'wf_wps_facet:hydrusAssemblyWF\:start-deposit\:completed',
    # ].join(' AND '),

    # :fq => [
    #   'has_model_s:info\:fedora/afmodel\:Hydrus_AdminPolicyObject',
    #   "roleMetadata_role_person_identifier_t:#{user}",
    # ].join(' AND '),
    # :fl => [
    #   'roleMetadata_role_type_t',
    #   'roleMetadata_role_person_identifier_t',
    #   'identityMetadata_objectId_t',

    # roleMetadata_role_person_identifier_t
    # :fq => 'has_model_s:info\:fedora/afmodel\:Hydrus_AdminPolicyObject',
    # :fq => 'has_model_s:info\:fedora/afmodel\:Hydrus_Collection',
    # :fq => 'has_model_s:info\:fedora/afmodel\:Hydrus_Item',
    # :fq => 'has_model_s:info\:fedora/afmodel\:Dor_AdminPolicyObject',


  solr_response = Blacklight.solr.find(h)
  document_list = solr_response.docs.map {|doc| SolrDocument.new(doc, solr_response)}  
  return [solr_response, document_list]
end

def solr_query(*args)
  resp, sdocs = run_solr_query(args.first)
  ap resp
  # ap resp['response']['numFound']
  # ap resp.docs.map { |d| d['identityMetadata_objectId_t'].first }
end

def show_keys(*args)
  rmd = role_md()
  sdoc = rmd.to_solr
  sdoc.keys.each { |k|
    next if k =~ /_\d+_/
    puts k
    sdoc[k].each { |v| puts "  #{v}" }
  }
end

def zzz(*args)
  druid = "druid:#{args.first}"
  hi = Hydrus::Collection.find druid
  wf = hi.workflows
  sdoc = wf.to_solr
  puts hi.workflows.ng_xml
  ap sdoc
  sdoc.keys.each { |k|
    next if k =~ /_\d+_/
    puts k
    sdoc[k].each { |v| puts "  #{v}" }
  }
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
