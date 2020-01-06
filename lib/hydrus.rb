module Hydrus
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
    [
      # Ur-APO
      'druid:bb000bb0000',
      # APOs.
      'druid:bb000bb0002',
      'druid:bb000bb0008',
      'druid:bb000bb0009',
      # Collections.
      'druid:bb000bb0003',
      'druid:bb000bb0004',
      'druid:oo000oo0010',
      # Items.
      'druid:bb123bb1234',
      'druid:bb123bb5432',
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
    Hash[pids.zip(xmls)]
  end

  # @param [String] pid  a PID for a Hydrus fixture
  # Reads the corresponding file from the fixture directory and returns
  # the content. Used when restoring fixture objects in a Hydrus rake task
  # and during testing.
  def self.fixture_foxml(pid)
    f = File.join('spec/fixtures', "#{pid.sub(/:/, '_')}.foxml.xml")
    IO.read(f)
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
    opts[:output_name] ||= 'profile'
    opts[:min_percent] ||= 0
    # Run the code being profiled.
    RubyProf.start
    yield
    profile_results = RubyProf.stop
    # Generate HTML report.
    fname = "#{opts[:output_dir]}/#{opts[:output_name]}-graph.html"
    File.open(fname, 'w') do |f|
      p = RubyProf::GraphHtmlPrinter.new(profile_results)
      p.print(f, min_percent: opts[:min_percent])
    end
  end
end
