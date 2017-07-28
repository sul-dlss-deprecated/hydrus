# frozen_string_literal: true

class Hydrus::RemediationRunner

  include Hydrus::SolrQueryable

  attr_accessor(
    :pid,
    :object_type,
    :object_version,
    :remed_method,
    :remed_version,
    :fobj,
    :log,
    :needs_versioning,
    :no_versioning,
    :no_save,
    :force,
    :problems
  )

  LOWEST_VERSION = '0000.00.00a'

  # Creates a new RemediationRunner.
  # Typically invoked via the remediations/run.rb script.
  def initialize(opts = {})
    # Unpack options passed on command line.
    @force         = opts[:force]
    @no_versioning = opts[:no_versioning]
    @no_save       = opts[:no_save]
    # Set values we always need -- eg, for logging.
    @remed_version = LOWEST_VERSION
    @pid           = 'NO_PID_YET'
    @problems      = Set.new
    # Set up the logger.
    @log           = Logger.new("#{Rails.root}/log/remediation.log", 10, 10240000)
    @log.formatter = proc { |severity, datetime, progname, msg|
      "#{severity}: #{datetime}: #{pid}: #{remed_method}: #{msg}\n"
    }
  end

  # Runs all remediations for all Hydrus objects.
  # The all_hydrus_objects() method returns a list of hashes (one per object)
  # obtained via a SOLR query. Each hash contains the following:
  #   :pid
  #   :object_type     # String: Item, Collection, or AdminPolicyObject
  #   :object_version  # Used to determine whether a remediation needs to run.
  def run
    log.info('====================')
    log.info('run() started')
    rems = discover_remediations()
    all_hydrus_objects().each do |h|
      rems.each do |rem|
        send(rem, h)
      end
    end
    if problems.size > 0
      msgs = ['', 'Check the log for problems with the following objects:']
      msgs << problems.to_a.sort.map { |p| "  #{p}" }
      warn msgs.join("\n")
    end
  end

  # Finds remediation scripts in the remediations directory. Requires those
  # files, and returns a list of the corresponding remediation method names.
  # For example:
  #   script             = 'remediations/2013.02.27a.rb'
  #   remediation method = 'remediation_2013_02_27a'
  def discover_remediations
    g = File.expand_path(File.join(Rails.root, 'remediations', '2*.rb'))
    remediations = Dir.glob(g)
    methods = []
    remediations.each do |r|
      require r
      m = File.basename(r, '.rb').gsub(/\./, '_')
      methods << 'remediation_' + m
    end
    methods.sort
  end

  # Called by a remediation method, which always receives one of the
  # hashes from all_hydrus_objects(). Unpacks that hash into various
  # attributes, and also stores the method name and associated version
  # number associated with the running remediation method.
  def unpack_args(h, remediation_method)
    # Unpack the object's hash from the SOLR query.
    @pid            = h[:pid]
    @object_type    = h[:object_type]
    @object_version = h[:object_version] || LOWEST_VERSION
    # Store info about the currently running remediation method.
    @remed_method   = remediation_method.to_s
    @remed_version  = @remed_method.sub(/\A\D+/, '').gsub(/_/, '.')
    # Log that we've started.
    log.info('----')
    log.info("started (#{object_type})")
  end

  # Loads up the Fedora object.
  def load_fedora_object
    log.info('loading fedora object')
    @fobj = ActiveFedora::Base.find(@pid, cast: true)
  end

  # Returns true if the currently running remediation method needs to be
  # applied to the currently loaded Fedora object, and logs accordingly.
  def remediation_is_needed
    msg = 'skipping'
    msg = 'running in --force mode' if force
    msg = 'is needed' if remed_version > object_version
    log.info(msg)
    msg != 'skipping'
  end

  # Some code to wrap version-handling and save-handling around the
  # particular steps of a remediation method. Takes the remediation
  # code via a block.
  def do_remediation
    # Open new version if necessary.
    self.needs_versioning = fobj.is_item? && fobj.is_published
    self.needs_versioning = false if no_versioning
    open_new_version_of_object()
    # Run the remediation code that was passed via a block,
    # and update the object's version to the version associated
    # with the currently running remediation method.
    log.info('starting remediation code')
    yield
    log.info('finished remediation code')
    fobj.object_version = remed_version
    # Save object, and close version if necessary.
    try_to_save_object()
    close_version_of_object()
  end

  # Tries to open a new administrative version of the fedora object, if needed.
  def open_new_version_of_object
    return unless needs_versioning
    begin
      fobj.open_new_version(description: remed_method,
                            significance: :admin,
                            is_remediation: true)
      log.info('open_new_version(success)')
    rescue Exception => e
      self.needs_versioning = false # So we won't try to close the version.
      log_warning("open_new_version(FAILED): #{e.message}")
    end
  end

  # Tries to save the fedora object.
  def try_to_save_object
    return if no_save
    log.info('trying to save')
    if fobj.save(is_remediation: true)
      log.info('saved')
    else
      es = fobj.errors
      msg = es ? es.messages.inspect : 'unknown reason'
      log_warning("save failed: #{msg}")
    end
  end

  # Tries to close the version.
  def close_version_of_object
    return unless needs_versioning
    begin
      fobj.close_version(is_remediation: true)
      log.info('close_version(success)')
    rescue Exception => e
      log_warning("close_version(FAILED): #{e.message}")
    end
  end

  # Keep track of PIDs with problems.
  def log_warning(msg)
    problems.add(pid)
    log.warn(msg)
  end

end
