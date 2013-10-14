module Hydrus


  # the possible types of items that can be created, hash of display value (keys) and values to store in object (value)
  def self.item_types
    {
      "article"       => "article",
      "audio - music" => "audio - music",   
      "audio - spoken" => "audio - spoken",   
      "class project" => "class project",
      "computer game" => "computer game",
      "conference paper / presentation" => "conference paper / presentation",  
      "data set"      => "dataset",
      "other"         => "other",      
      "thesis"        => "thesis",
      "technical report" => "technical report",
      "video" => "video"    
    }
  end

  def self.default_item_type
    Hydrus::Application.config.default_item_type
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
    return {
      'Creative Commons Licenses'  => "creativeCommons",
      'Open Data Commons Licenses' => "openDataCommons",
    }
  end

  # Should consolidate with info in license_groups().
  def self.license_group_urls
    return {
      "creativeCommons" => 'http://creativecommons.org/licenses/',
      "openDataCommons" => 'http://opendatacommons.org/licenses/',
    }
  end

  # Takes a license code: cc-by, pddl, none, ...
  # Returns the corresponding text description of that license.
  def self.license_human(code)
    code = 'none' if code.blank?
    lic = license_groups.map(&:last).flatten(1).find { |txt, c| c == code }
    return lic ? lic.first : "Unknown license"
  end

  # Takes a license code: cc-by, pddl, none, ...
  # Returns the corresponding license group code: eg, creativeCommons.
  def self.license_group_code(code)
    Hydrus.license_groups.each do |grp, licenses|
      licenses.each do |txt, c|
        return Hydrus.license_commons[grp] if c == code
      end
    end
    return nil
  end

  # Takes a symbol (:collection or :item).
  # Returns a hash of two hash, each having object_status as its
  # keys and human readable labels as values.
  def self.status_labels(typ, status = nil)
    h = {
      :collection => {
        'draft'             => "draft",
        'published_open'    => "published",
        'published_closed'  => "published",
      },
      :item       => {
        'draft'             => "draft",
        'awaiting_approval' => "waiting for approval",
        'returned'          => "item returned",
        'published'         => "published",
      },
    }
    return status ? h[typ] : h[typ]
  end

  # Takes an object_status value.
  # Returns its corresponding label.
  def self.status_label(typ, status)
    return status_labels(typ)[status]
  end

  def self.stanford_terms_of_use
    return '
      User agrees that, where applicable, content will not be used to identify
      or to otherwise infringe the privacy or confidentiality rights of
      individuals.  Content distributed via the Stanford Digital Repository may
      be subject to additional license and use restrictions applied by the
      depositor.
    '.squish
  end

  # Returns a hash of info needed for licenses in the APO.
  # Keys correspond to the license_option in the OM terminology.
  # Values are displayed in the web form.
  def self.license_types
    return {
      'none'   => 'no license',
      'varies' => 'varies -- contributor may select a license for each item, with a default of',
      'fixed'  => 'required license -- applies to all items in the collection',
    }
  end

  # WARNING - the keys of this hash (which appear in the radio buttons in the
  # colelction edit page) are used in the collection model to trigger specific
  # getting and setting behavior of embargo lengths. If you change these keys
  # here, you need to update the collection model as well
  def self.embargo_types
    {'none'   => 'No delay -- release all items as soon as they are deposited',
     'varies' => 'Varies -- select a release date per item, from "now" to a maximum of',
     'fixed'  => 'Fixed -- delay release of all items for'}
  end

  def self.visibility_types
    {'everyone' => 'Everyone -- all items in this collection will be public',
     'varies'   => 'Varies -- default is public, but you can choose to restrict some items to Stanford community',
     'stanford' => 'Stanford community -- all items will be visible only to Stanford-authenticated users'}
  end

  def self.embargo_terms
    {'6 months after deposit' => '6 months',
     '1 year after deposit'   => '1 year',
     '2 years after deposit'  => '2 years',
     '3 years after deposit'  => '3 years'}
  end

  # By default, returns a hash-of-hashes of roles and their UI labels and help texts.
  # The user can supply the following values in the options list:
  #   :collection_level   Prune the item-level roles from the hash.
  #   :only_labels        Return a simple hash of just labels.
  #   :only_help          "                            help texts.
  #   :only_lesser        "                            less powerful (implied) roles.
  #
  # NOTE: although collection-manager might be viewed as a role implied
  # by collection-depositor, we have decided not to prune the manager role
  # from depositors.
  def self.role_labels(*opts)
    # The data.
    h = {
      # Item-level roles.
      'hydrus-item-depositor' => {
        :label  => "Item Depositor",
        :help   => "This is the original depositor of the item and can peform any action with the item",
        :lesser => %w(hydrus-item-manager),
      },
      'hydrus-item-manager' => {
        :label  => "Item Manager",
        :help   => "These users can edit the item",
        :lesser => %w(),
      },
      # Collection-level roles.
      'hydrus-collection-depositor' => {
        :label  => "Owner",
        :help   => "This user is the collection owner and can perform any action with the collection",
        :lesser => %w(hydrus-collection-reviewer hydrus-collection-item-depositor hydrus-collection-viewer),
      },
      'hydrus-collection-manager' => {
        :label  => "Manager",
        :help   => "These users can edit collection details, and add and review items in the collection",
        :lesser => %w(hydrus-collection-reviewer hydrus-collection-item-depositor hydrus-collection-viewer),
      },
      'hydrus-collection-reviewer' => {
        :label  => "Reviewer",
        :help   => "These users can review items in the collection, but not add new items",
        :lesser => %w(hydrus-collection-viewer),
      },
      'hydrus-collection-item-depositor' => {
        :label  => "Depositor",
        :help   => "These users can add items to the collection, but cannot act as reviewers",
        :lesser => %w(hydrus-collection-viewer),
      },
      'hydrus-collection-viewer' => {
        :label  => "Viewer",
        :help   => "These users can view items in the collection only",
        :lesser => %w(),
      },
    }
    # Remove item-level roles.
    if opts.include?(:collection_level)
      h.delete('hydrus-item-depositor')
      h.delete('hydrus-item-manager')
    end
    # Convert to a simple hash of just labels or just help.
    k = opts.include?(:only_labels) ? :label  :
        opts.include?(:only_help)   ? :help   :
        opts.include?(:only_lesser) ? :lesser : nil
    h.keys.each { |role| h[role] = h[role][k] } if k
    # Return hash.
    return h
  end

  def self.roles_for_ui(roles)
    labels = role_labels(:only_labels)
    return roles.map { |r| labels[r] }
  end

  # All of our fixture PIDs, in order: APOs, then Collections, then Items.
  # Items can't be loaded until their APOs and Collections are in Fedora;
  # otherwise the dor-services indexing code will blow up.
  #
  # We define the PIDs here because we need to access them in two contexts:
  #   - rake: when loading fixtures
  #   - spec_helper.rb: when restoring fixtures during testing
  #
  # The second usage might disappear if we are able to improve Rubydora's
  # transaction features to support fixture restoration.
  def self.fixture_pids
    return [
      # Ur-APO and the workflow objects.
      'druid:oo000oo0000',
      'druid:oo000oo0099',  # hydrusAssemblyWF
      'druid:oo000oo0098',  # versioningWF
      # APOs.
      'druid:oo000oo0002',
      'druid:oo000oo0008',
      'druid:oo000oo0009',
      # Collections.
      'druid:oo000oo0003',
      'druid:oo000oo0004',
      'druid:oo000oo0010',
      # Items.
      'druid:oo000oo0001',
      'druid:oo000oo0005',
      'druid:oo000oo0006',
      'druid:oo000oo0007',
      'druid:oo000oo0011',
      'druid:oo000oo0012',
      'druid:oo000oo0013',
    ]
  end

  # Returns a hash of fixtures, with PIDs as keys and foxml as values.
  # Used to restore fixture after each Rspec test.
  def self.all_fixture_foxml
    pids = fixture_pids()
    xmls = pids.map { |p| fixture_foxml(p) }
    return Hash[ pids.zip(xmls) ]
  end

  # Takes a PID for a Hydrus fixtures, and an optional hash with the :is_wf
  # key. Reads the corresponding file from the fixture directory and returns
  # the content. Used when restoring fixture objects in a Hydrus rake task
  # and during testing.
  def self.fixture_foxml(pid, opts = {})
    p = pid.sub(/:/, '_')
    w = opts[:is_wf] ? 'workflow_xml/' : ''
    e = opts[:is_wf] ? ''              : '.foxml'
    f = File.join('spec/fixtures', w, p + e + '.xml')
    return IO.read(f)
  end

  # A pretty-printing method used during debugging.
  # Takes an argument and prints it with aweseome_print.
  def self.ap_dump(arg, file_handle = STDOUT)
    d = '=' * 80
    file_handle.puts(d, caller[0], arg.ai(:plain => true), d)
  end

  # To use this profiling method, wrap the code you want to profile like this,
  # setting the desired value for :min_percent.
  #
  #   Hydrus.profile(:min_percent => 5) {
  #     # Code here...
  #   }
  def self.profile(opts = {})
    # Setup options.
    opts[:output_dir]  ||= "#{Rails.root}/tmp/profiling"
    opts[:output_name] ||= "profile"
    opts[:min_percent] ||= 0
    # Run the code being profiled.
    RubyProf.start
    yield
    profile_results = RubyProf.stop
    # Generate HTML report.
    fname = "#{opts[:output_dir]}/#{opts[:output_name]}-graph.html"
    File.open(fname, 'w') do |f|
      p = RubyProf::GraphHtmlPrinter.new(profile_results)
      p.print(f, :min_percent => opts[:min_percent])
    end
  end

end
