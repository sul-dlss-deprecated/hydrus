# A script used to generate new collections and items
# on a developer's machine.

def create_test_collection(*args)
  # Create a new Collection and set all required values.
  user                       = args.shift || 'archivist1'
  user                       = User.new(:email => "#{user}@example.com")
  hc                         = Hydrus::Collection.create(user)
  hc.title                   = "Title for: #{hc.pid}"
  hc.abstract                = 'abstract'
  hc.contact                 = 'contact'
  hc.embargo_option          = 'varies'
  hc.embargo_terms           = '2 years'
  hc.license_option          = 'varies'
  hc.license                 = 'cc-by-nc'
  hc.visibility_option       = 'varies'
  hc.visibility              = 'world'
  hc.requires_human_approval = 'yes'
  # Publish, save, and return a refreshed object.
  hc.publish('true') if args.delete('--publish')
  hc.save
  puts "Created collection: user=#{user} pid=#{hc.pid}"
  return Hydrus::Collection.find(hc.pid)
end

def create_test_item(*args)
  # Create a new Item and set all required values.
  hc_pid         = args.shift
  user           = args.shift || 'archivist1'
  user           = User.new(:email => "#{user}@example.com")
  hc_pid         = "druid:#{hc_pid}" unless hc_pid =~ /^druid:/
  hi             = Hydrus::Item.create(hc_pid, user)
  hi.title       = "Title for: #{hi.pid}"
  hi.abstract    = 'abstract'
  hi.contact     = 'contact'
  hi.person      = { "0" => "Nugent, Ted" }
  hi.person_role = { "0" => "Author" }
  hi.accepted_terms_of_deposit = 'yes'
  hi.reviewed_release_settings = 'yes'
  # Create a file for the Item.
  f       = Hydrus::ObjectFile.new
  f.pid   = hi.pid
  f.label = 'file'
  f.file  = File.open(__FILE__)
  # Publish and approve or disapprove.
  hi.publish()             if args.delete('--publish')
  hi.do_disapprove('blah') if args.delete('--disapprove')
  hi.do_approve()          if args.delete('--approve')
  # Save and return a refreshed object.
  f.save
  hi.save
  puts "Created item: user=#{user} pid=#{hi.pid}"
  return Hydrus::Item.find(hi.pid)
end

def create_test_batch(*args)
  # Takes args (or uses the default defined below) and invokes
  # methods to create new collections or items -- publishing, approving,
  # or disapproving them accordingly.
  args = %w(
    c
    cp i ip ip ia ia ia id
    cp i ip ip ia ia ia id i ip ip ia ia ia id
  ) unless args.size > 0
  hc = nil
  hi = nil
  args.each do |arg|
    opts = parse_batch_opts(arg)
    if opts.shift == 'c'
      hc = create_test_collection(*opts)
    else
      if hc && hc.is_published
        hi = create_test_item(hc.pid, *opts)
      else
        help("Cannot create item without creating a published collection first")
      end
    end
  end
end

def parse_batch_opts(arg)
  # Takes a string and returns the corresponding array of options
  # that will be passed to one of the create_*() methods.
  opts = {
    :c  => %w(c),
    :cp => %w(c --publish),
    :i  => %w(i),
    :ip => %w(i --publish),
    :ia => %w(i --publish --approve),
    :id => %w(i --publish --disapprove),
  }
  opts = opts[arg.to_sym]
  return opts if opts
  help("Invalid batch parameter: #{arg}")
end

def help(msg = nil)
  # Prints usage message and quits.
  puts msg if msg
  rrf = "rails runner #{__FILE__}"
  puts <<-EOS.gsub(/^ {4}/, '')
    Usage:
        #{rrf} collection [USER] [--publish]
        #{rrf} item COLL_PID [USER] [--publish] [--approve | --disapprove]
        #{rrf} batch [c|cp|i|ip|ia|id]...
        #{rrf} batch # Uses defaults.
        #{rrf} help
  EOS
  exit
end

def main
  # Invokes the requested methods, passing any additional values
  # from ARGV to that method.
  args = ARGV.dup
  m    = (args.shift || 'NONE').to_sym
  ms   = {
    :collection => method(:create_test_collection),
    :item       => method(:create_test_item),
    :batch      => method(:create_test_batch),
  }
  help() unless ms.has_key?(m)
  ms[m].call(*args)
end

main()
