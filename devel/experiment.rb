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
    :q => '*:*',
    :fq => [
      'has_model_s:info\:fedora/afmodel\:Hydrus_AdminPolicyObject',
      "roleMetadata_role_person_identifier_t:#{user}",
    ].join(' AND '),
    :fl => [
      'roleMetadata_role_type_t',
      'roleMetadata_role_person_identifier_t',
      'identityMetadata_objectId_t',
    ].join(','),
    # roleMetadata_role_person_identifier_t
    # :fq => 'has_model_s:info\:fedora/afmodel\:Hydrus_AdminPolicyObject',
    # :fq => 'has_model_s:info\:fedora/afmodel\:Hydrus_Collection',
    # :fq => 'has_model_s:info\:fedora/afmodel\:Hydrus_Item',
    # :fq => 'has_model_s:info\:fedora/afmodel\:Dor_AdminPolicyObject',
  }
  solr_response = Blacklight.solr.find(h)
  document      = SolrDocument.new(solr_response.docs.first, solr_response)
  return [solr_response, document]
end

def solr_query(*args)
  resp, sdoc = run_solr_query(args.first)
  # ap resp['response']
  ap resp.docs.map { |d| d['identityMetadata_objectId_t'].first }
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

method(ARGV[0]).call(*ARGV[1..99])
