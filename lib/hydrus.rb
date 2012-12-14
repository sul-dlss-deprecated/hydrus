module Hydrus

  def self.ap_dump(arg, file_handle = STDOUT)
    d = '=' * 80
    file_handle.puts(d, caller[0], arg.ai(:plain => true), d)
  end

  # To use this profiling method:
  #
  #   - Uncomment ruby-prof in the Gemfile.
  #   - Uncomment the code below.
  #   - Wrap the code you want to profile like this:
  #       Hydrus.profile() {
  #         # Code here...
  #       }

  # def self.profile(opts = {})
  #   # Setup options.
  #   opts[:output_dir]  ||= "#{Rails.root}/tmp/profiling"
  #   opts[:output_name] ||= "profile"
  #   opts[:min_percent] ||= 0
  #   # Run the code being profiled.
  #   RubyProf.start
  #   yield
  #   profile_results = RubyProf.stop
  #   # Generate HTML report.
  #   fname = "#{opts[:output_dir]}/#{opts[:output_name]}-graph.html"
  #   File.open(fname, 'w') do |f|
  #     p = RubyProf::GraphHtmlPrinter.new(profile_results)
  #     p.print(f, :min_percent => opts[:min_percent])
  #   end
  # end

end
