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
    return [
      # Ur-APO and the hydrusAssembly workflow object.
      'druid:oo000oo0000',
      'druid:oo000oo0099',
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
  def self.fixture_foxml
    fps   = fixture_pids()
    foxml = fps.map { |p| p.sub /:/, '_' }.
                map { |p| "spec/fixtures/#{p}.foxml.xml" }.
                map { |p| IO.read(p) }
    return Hash[ fps.zip(foxml) ]
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
