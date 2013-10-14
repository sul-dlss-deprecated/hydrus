# A script used to generate new collections and items
# on a developer's machine.

def parse_do_opts(args, *ks)
  opts = ks.map { |k| args.delete("--#{k}") }
  return Hash[ ks.zip(opts) ]
end

def create_test_collection(*args)
  # Create a new Collection and set all required values.
  do_opts           = parse_do_opts(args, :open)
  user              = args.shift || 'archivist1'
  user              = User.new(:email => "#{user}@example.com")
  hc                = Hydrus::Collection.create(user)
  hc.title          = "Title for: #{hc.pid}"
  hc.abstract       = 'abstract'
  hc.contact        = 'foo@bar.com'
  hc.embargo_option = 'varies'
  hc.embargo_terms  = '2 years'
  hc.license_option = 'varies'
  hc.license        = 'cc-by-nc'
  hc.visibility_option_value = 'varies'
  hc.requires_human_approval = 'yes'
  # Open, save, and return a refreshed object.
  hc.open if do_opts[:open]
  hc.save
  puts "Created collection: user=#{user} apo_pid=#{hc.apo.pid} pid=#{hc.pid}"
  return Hydrus::Collection.find(hc.pid)
end

def create_test_item(*args)
  # Create a new Item and set all required values.
  do_opts        = parse_do_opts(args, :submit_for_approval, :disapprove, :approve)
  hc_pid         = args.shift
  user           = args.shift || 'archivist1'
  user           = User.new(:email => "#{user}@example.com")
  hc_pid         = "druid:#{hc_pid}" unless hc_pid =~ /^druid:/
  hi             = Hydrus::Item.create(hc_pid, user)
  hi.title       = "Title for: #{hi.pid}"
  hi.abstract    = 'abstract'
  hi.contact     = 'foo@bar.com'
  hi.license     = 'cc-by-nc'
  hi.keywords    = "foo,bar"
  hi.visibility  = 'stanford'
  hi.contributors = {
    "0" => {"name"=>"Nugent, Ted", "role_key"=>"personal_author"},
    "1" => {"name"=>"EMI",         "role_key"=>"corporate_sponsor"},
  }
  hi.accepted_terms_of_deposit = 'yes'
  hi.reviewed_release_settings = 'yes'
  # Create a file for the Item.
  f       = Hydrus::ObjectFile.new
  f.pid   = hi.pid
  f.label = 'file'
  f.file  = File.open(__FILE__)
  f.save
  # Submit for approval and approve/disapprove.
  hi.submit_for_approval() if do_opts[:submit_for_approval]
  hi.disapprove('blah')    if do_opts[:disapprove]
  hi.approve()             if do_opts[:approve]
  # Save and return a refreshed object.
  hi.save
  puts "Created item: user=#{user} pid=#{hi.pid}"
  return Hydrus::Item.find(hi.pid)
end

def create_test_batch(*args)
  # Takes args (or uses the default defined below) and invokes
  # methods to create new collections or items -- submitting, approving,
  # or disapproving them accordingly.
  args = %w(
    c
    co i is is ia ia ia id
    co i is is ia ia ia id i is is ia ia ia id
  ) unless args.size > 0
  hc = nil
  hi = nil
  args.each do |arg|
    opts = parse_batch_opts(arg)
    if opts.shift == 'c'
      hc = create_test_collection('archivist1', *opts)
    else
      if hc && hc.is_open?
        hi = create_test_item(hc.pid, 'archivist1', *opts)
      else
        help("Cannot create item without opening collection first")
      end
    end
  end
end

def parse_batch_opts(arg)
  # Takes a string and returns the corresponding array of options
  # that will be passed to one of the create_*() methods.
  opts = {
    :c  => %w(c),
    :co => %w(c --open),
    :i  => %w(i),
    :is => %w(i --submit_for_approval),
    :ia => %w(i --submit_for_approval --approve),
    :id => %w(i --submit_for_approval --disapprove),
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
        #{rrf} collection    [USER] [--open]
        #{rrf} item COLL_PID [USER] [--submit_for_approval] [--approve | --disapprove]
        #{rrf} batch [c|co|i|is|ia|id]...
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
