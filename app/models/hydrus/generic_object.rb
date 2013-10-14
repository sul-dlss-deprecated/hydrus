class Hydrus::GenericObject < Dor::Item

  include Hydrus::GenericObjectStuff

  attr_accessor :files_were_changed

  validates :pid, :is_druid => true
  validate :check_contact_email_format, :if => :should_validate

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
    errors.add(:contact, "is not a valid email address")
  end

  # Notes:
  #   - We override save() so we can control whether editing events are logged.
  #   - This method is called via the normal operations of the web app, and
  #     during Hydrus remediations.
  #   - The :no_super is used to prevent the super() call during unit tests.
  def save(opts = {})
    # beautify_datastream(:descMetadata) unless opts[:no_beautify]
    unless opts[:is_remediation]
      self.last_modify_time = HyTime.now_datetime
      log_editing_events() unless opts[:no_edit_logging]
    end
    super() unless opts[:no_super]
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
    return nd.to_xml
  end

  def discover_access
    return rightsMetadata.discover_access.first
  end

  def purl_url
   "#{Dor::Config.purl.base_url}#{pid.gsub('druid:','')}"
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
        descMetadata.typeOfResource="software, multimedia"
        descMetadata.genre="dataset"
      when 'thesis'
        descMetadata.typeOfResource="text"
        descMetadata.insert_genre
        descMetadata.genre="thesis"
        #this is messy but I couldnt get OM to do what I needed it to
        set_genre_authority_to_marc descMetadata
      when 'article'
        descMetadata.typeOfResource="text"
        descMetadata.genre="article"
        set_genre_authority_to_marc descMetadata
      when 'class project'
        descMetadata.typeOfResource="text"
        descMetadata.genre="student project report"
      when 'computer game'
        descMetadata.typeOfResource="software, multimedia"
        descMetadata.genre="game"
      when 'audio - music'
        descMetadata.typeOfResource="sound recording-musical"
        descMetadata.genre="sound"
        set_genre_authority_to_marc descMetadata
      when 'audio - spoken'
        descMetadata.typeOfResource="sound recording-nonmusical"
        descMetadata.genre="sound"
        set_genre_authority_to_marc descMetadata
      when 'video'
        descMetadata.typeOfResource="moving image"
        descMetadata.genre="motion picture"
        set_genre_authority_to_marc descMetadata
      when 'conference paper / presentation'
        descMetadata.typeOfResource="text"
        descMetadata.genre="conference publication"
        set_genre_authority_to_marc descMetadata
      when 'technical report'
        descMetadata.typeOfResource="text"
        descMetadata.genre="technical report"
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

  # Returns a human readable label corresponding to the object's status.
  def status_label
    h1 = Hydrus.status_labels(:collection)
    h2 = Hydrus.status_labels(:item)
    return h1.merge(h2)[object_status]
  end

  # Registers an object in Dor, and returns it.
  def self.register_dor_object(registration_params = {})
    unless [:object_type, :user, :admin_policy].all? { |k| registration_params.has_key? k }
      raise ArgumentError.new "register_dor_object requires :object_type, :admin_policy, :user parameters"
    end
    return Dor::RegistrationService.register_object({
      :source_id         => { "Hydrus" => "#{registration_params[:object_type]}-#{registration_params[:user]}-#{HyTime.now_datetime_full}" },
      :label             => "Hydrus",
      :tags              => ["Project : Hydrus"],
      :initiate_workflow => [Dor::Config.hydrus.app_workflow]}.merge(registration_params))
  end

  def recipients_for_object_returned_email
    is_collection? ? owner : item_depositor_id
  end

  def send_object_returned_email_notification(opts={})
    return if recipients_for_object_returned_email.blank?
    email=HydrusMailer.object_returned(:returned_by => @current_user, :object => self, :item_url=>opts[:item_url])
    email.deliver unless email.blank?
  end

  def purl_page_ready?
    return RestClient.get(purl_url) { |resp, req, res| resp }.code == 200
  end

end
