class Hydrus::GenericObject < Dor::Item

  include Hydrus::GenericObjectStuff

  attr_accessor :files_were_changed

  validates :pid, is_druid: true
  validate :check_contact_email_format, if: :should_validate

  # We are using the validates_email_format_of gem to check email addresses.
  # Normally, you can use this tool with a simple validates() call:
  #
  #   validates :contact, :email_format => {:message => '...'}
  #
  # However, that resulted in an extraneous :contact key in the errors.messages
  # hash whenever a Collection had a validation error not involving the contact
  # email. This approach solved the problem.
  def check_contact_email_format
    problems = ValidatesEmailFormatOf::validate_email_format(contact)
    return if problems.nil?
    errors.add(:contact, 'must contain a single valid email address')
  end

  # the pid without the druid: prefix
  def dru
    pid.gsub('druid:','')
  end

  # Notes:
  #   - We override save() so we can control whether editing events are logged.
  #   - This method is called via the normal operations of the web app, and
  #     during Hydrus remediations.
  #   - The :no_super is used to prevent the super() call during unit tests.
  def save(opts = {})
    if new_record?
      # dor-services calls save before any metadata is applied, so don't validate
      super(validate: false) unless opts[:no_super]
    else
      # beautify_datastream(:descMetadata) unless opts[:no_beautify]
      unless opts[:is_remediation]
        self.last_modify_time = HyTime.now_datetime
        log_editing_events() unless opts[:no_edit_logging]
      end
      super() unless opts[:no_super]
    end
  end

  # Takes a datastream name, such as :descMetadata or 'rightsMetadata'.
  # Replaces that datastream's XML content with a beautified version of the XML.
  # NOTE: not being used currently, because strange problems occurred
  #       when this method was invoked in save().
  def beautify_datastream(dsid)
    ds         = datastreams[dsid.to_s]
    ds.content = beautified_xml(ds.content)
  end

  # Takes some XML as a String.
  # Creates a Nokogiri document based on that XML, minus whitespace-only nodes.
  # Returns a new XML string, using Nokogiri's default indentation rules to
  # produce nice looking XML.
  # NOTE: not being used currently, because strange problems occurred
  #       when this method was invoked via save().
  def beautified_xml(orig_xml)
    nd = Nokogiri::XML(orig_xml, &:noblanks)
    nd.to_xml
  end

  def get_fedora_item(pid)
    ActiveFedora::Base.find(pid, cast: true)
  end

  def discover_access
    rightsMetadata.discover_access.first
  end

  def purl_url
   "#{Dor::Config.purl.base_url}#{dru}"
  end

  # Takes an item_type: :dataset, etc. for items, or just :collection for collections.
  # Adds some Hydrus-specific information to the identityMetadata.
  def set_item_type(typ)
    self.hydrusProperties.item_type=typ.to_s
    if typ == :collection
      if respond_to? :set_collection_type
        set_collection_type
      else
        # DEPRECATED. MAYBE DEAD CODE?
        identityMetadata.add_value(:objectType, 'set')
        identityMetadata.content_will_change!
        descMetadata.ng_xml.search('//mods:mods/mods:typeOfResource', 'mods' => 'http://www.loc.gov/mods/v3').each do |node|
  				node['collection']='yes'
        end
      end
    else
      case typ
      when 'dataset'
        descMetadata.typeOfResource='software, multimedia'
        descMetadata.genre='dataset'
      when 'thesis'
        descMetadata.typeOfResource='text'
        descMetadata.insert_genre
        descMetadata.genre='thesis'
        #this is messy but I couldnt get OM to do what I needed it to
        set_genre_authority_to_marc descMetadata
      when 'article'
        descMetadata.typeOfResource='text'
        descMetadata.genre='article'
        set_genre_authority_to_marc descMetadata
      when 'class project'
        descMetadata.typeOfResource='text'
        descMetadata.genre='student project report'
      when 'computer game'
        descMetadata.typeOfResource='software, multimedia'
        descMetadata.genre='game'
      when 'audio - music'
        descMetadata.typeOfResource='sound recording-musical'
        descMetadata.genre='sound'
        set_genre_authority_to_marc descMetadata
      when 'audio - spoken'
        descMetadata.typeOfResource='sound recording-nonmusical'
        descMetadata.genre='sound'
        set_genre_authority_to_marc descMetadata
      when 'video'
        descMetadata.typeOfResource='moving image'
        descMetadata.genre='motion picture'
        set_genre_authority_to_marc descMetadata
      when 'conference paper / presentation'
        descMetadata.typeOfResource='text'
        descMetadata.genre='conference publication'
        set_genre_authority_to_marc descMetadata
      when 'technical report'
        descMetadata.typeOfResource='text'
        descMetadata.genre='technical report'
        set_genre_authority_to_marc descMetadata
      when 'archival mixed material'
        descMetadata.typeOfResource='mixed material'
        set_type_of_resource_collection descMetadata
      when 'image'
        descMetadata.typeOfResource='still image'
      when 'software'
        descMetadata.typeOfResource='software, multimedia'
      when 'textbook'
        descMetadata.typeOfResource='text'
        descMetadata.genre='instruction'
        set_genre_authority_to_marc descMetadata
      else
        descMetadata.typeOfResource=typ.to_s
      end
      descMetadata.content_will_change!
    end
  end
  def set_genre_authority_to_marc  descMetadata
    descMetadata.ng_xml.search('//mods:genre', 'mods' => 'http://www.loc.gov/mods/v3').first['authority'] = 'marcgt'
  end
  def remove_genre_authority descMetadata
    node = descMetadata.ng_xml.search('//mods:genre', 'mods' => 'http://www.loc.gov/mods/v3').first
    node.remove_attribute('authority') if node
  end

  def set_type_of_resource_collection(descMetadata)
    descMetadata.ng_xml.search('//mods:typeOfResource', 'mods' => 'http://www.loc.gov/mods/v3').first['manuscript'] = 'yes'
  end

  def remove_type_of_resource_collection(descMetadata)
     node = descMetadata.ng_xml.search('//mods:typeOfResource', 'mods' => 'http://www.loc.gov/mods/v3').first
     node.remove_attribute('manuscript') if node
  end

  # the possible types of items that can be created, hash of display value (keys) and values to store in object (value)
  def self.item_types
    {
      'archival mixed material' => 'archival mixed material',
      'article'       => 'article',
      'audio - music' => 'audio - music',
      'audio - spoken' => 'audio - spoken',
      'class project' => 'class project',
      'computer game' => 'computer game',
      'conference paper / presentation' => 'conference paper / presentation',
      'data set'      => 'dataset',
      'image'         => 'image',
      'software'      => 'software',
      'other'         => 'other',
      'technical report' => 'technical report',
      'textbook'      => 'textbook',
      'thesis'        => 'thesis',
      'video' => 'video'
    }
  end

  # Returns a data structure intended to be passed into
  # grouped_options_for_select(). This is an awkward approach (too
  # view-centric), leading to some minor data duplication in other
  # license-related methods, along with some overly complex lookup methods.
  def self.license_groups
    [
      ['None',  [
        ['No license', 'none'],
      ]],
      ['Creative Commons Licenses',  [
        ['CC BY Attribution'                                 , 'cc-by'],
        ['CC BY-SA Attribution Share Alike'                  , 'cc-by-sa'],
        ['CC BY-ND Attribution-NoDerivs'                     , 'cc-by-nd'],
        ['CC BY-NC Attribution-NonCommercial'                , 'cc-by-nc'],
        ['CC BY-NC-SA Attribution-NonCommercial-ShareAlike'  , 'cc-by-nc-sa'],
        ['CC BY-NC-ND Attribution-NonCommercial-NoDerivs'    , 'cc-by-nc-nd'],
      ]],
      ['Open Data Commons Licenses',  [
        ['PDDL Public Domain Dedication and License'         , 'pddl'],
        ['ODC-By Attribution License'                        , 'odc-by'],
        ['ODC-ODbl Open Database License'                    , 'odc-odbl'],
      ]],
    ]
  end

  # Should consolidate with info in license_groups().
  def self.license_commons
    {
      'Creative Commons Licenses'  => 'creativeCommons',
      'Open Data Commons Licenses' => 'openDataCommons',
    }
  end

  # Should consolidate with info in license_groups().
  def self.license_group_urls
    {
      'creativeCommons' => 'http://creativecommons.org/licenses/',
      'openDataCommons' => 'http://opendatacommons.org/licenses/',
    }
  end

  # Takes a license code: cc-by, pddl, none, ...
  # Returns the corresponding text description of that license.
  def self.license_human(code)
    code = 'none' if code.blank?
    lic = license_groups.map(&:last).flatten(1).find { |txt, c| c == code }
    lic ? lic.first : 'Unknown license'
  end

  # Takes a license code: cc-by, pddl, none, ...
  # Returns the corresponding license group code: eg, creativeCommons.
  def self.license_group_code(code)
    hgo = Hydrus::GenericObject
    hgo.license_groups.each do |grp, licenses|
      licenses.each do |txt, c|
        return hgo.license_commons[grp] if c == code
      end
    end
    nil
  end

  # Takes a symbol (:collection or :item).
  # Returns a hash of two hash, each having object_status as its
  # keys and human readable labels as values.
  def self.status_labels(typ, status = nil)
    h = {
      collection: {
        'draft'             => 'draft',
        'published_open'    => 'published',
        'published_closed'  => 'published',
      },
      item: {
        'draft'             => 'draft',
        'awaiting_approval' => 'waiting for approval',
        'returned'          => 'item returned',
        'published'         => 'published',
      },
    }
    status ? h[typ] : h[typ]
  end

  # Takes an object_status value.
  # Returns its corresponding label.
  def self.status_label(typ, status)
    status_labels(typ)[status]
  end

  # Returns a human readable label corresponding to the object's status.
  def status_label
    h1 = Hydrus::GenericObject.status_labels(:collection)
    h2 = Hydrus::GenericObject.status_labels(:item)
    h1.merge(h2)[object_status]
  end

  def self.stanford_terms_of_use
    '
      User agrees that, where applicable, content will not be used to identify
      or to otherwise infringe the privacy or confidentiality rights of
      individuals.  Content distributed via the Stanford Digital Repository may
      be subject to additional license and use restrictions applied by the
      depositor.
    '.squish
  end

  # Registers an object in Dor, and returns it.
  def self.register_dor_object(*args)
    params = self.dor_registration_params(*args)
    Dor::RegistrationService.register_object(params)
  end

  # Returns a hash of info needed to register a Dor object.
  def self.dor_registration_params(user_string, obj_typ, apo_pid)
    {
      object_type: obj_typ,
      admin_policy: apo_pid,
      source_id: { 'Hydrus' => "#{obj_typ}-#{user_string}-#{HyTime.now_datetime_full}" },
      label: 'Hydrus',
      tags: [Settings.hydrus.project_tag],
      initiate_workflow: [Dor::Config.hydrus.app_workflow],
    }
  end

  def recipients_for_object_returned_email
    is_collection? ? owner : item_depositor_id
  end

  def send_object_returned_email_notification(opts={})
    return if recipients_for_object_returned_email.blank?
    email=HydrusMailer.object_returned(returned_by: @current_user, object: self, item_url: opts[:item_url])
    email.deliver_now unless email.blank?
  end

  def purl_page_ready?
    RestClient.get(purl_url) { |resp, req, res| resp }.code == 200
  end

end
