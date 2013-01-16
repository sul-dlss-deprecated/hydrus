module Dor
  module Versionable
    extend ActiveSupport::Concern
    include Processable
    include Upgradable

    included do
      has_metadata :name => 'versionMetadata', :type => Dor::VersionMetadataDS, :label => 'Version Metadata', :autocreate => true
    end

    # Increments the version number and initializes versioningWF for the object
    # @raise [Dor::Exception] if the object hasn't been accessioned, or if a version is already opened
    def open_new_version
      raise Dor::Exception, 'Object net yet accessioned' unless(Dor::WorkflowService.get_lifecycle('dor', pid, 'accessioned'))
      if(new_version_open?)
        if(Dor::WorkflowService.get_active_lifecycle('dor', pid, 'submitted'))
          raise Dor::Exception, 'Recently closed version still needs to be accessioned'
        else
          raise Dor::Exception, 'Object already opened for versioning'
        end
      end

      ds = datastreams['versionMetadata']
      ds.increment_version
      ds.content = ds.ng_xml.to_s
      ds.save unless self.new_object?
      initialize_workflow 'versioningWF'
    end

    def current_version
      datastreams['versionMetadata'].current_version_id
    end

    # Sets versioningWF:submit-version to completed and initiates accessionWF for the object
    # @param [Hash] opts optional params
    # @option opts [String] :description describes the version change
    # @option opts [Symbol] :significance which part of the version tag to increment
    #  :major, :minor, :admin (see Dor::VersionTag#increment)
    # @option opts [String] :version_num version number to archive rows with. Otherwise, current version is used
    # @option opts [Boolean] :start_accesion set to true if you want accessioning to start (default), false otherwise
    # @raise [Dor::Exception] if the object hasn't been opened for versioning, or if accessionWF has
    #   already been instantiated or the current version is missing a tag or description
    def close_version(opts={})
      unless(opts.empty?)
        datastreams['versionMetadata'].update_current_version opts
      end

      raise Dor::Exception, 'latest version in versionMetadata requires tag and description before it can be closed' unless(datastreams['versionMetadata'].current_version_closeable?)
      raise Dor::Exception, 'Trying to close version on an object not opened for versioning' unless(new_version_open?)
      raise Dor::Exception, 'accessionWF already created for versioned object' if(Dor::WorkflowService.get_active_lifecycle('dor', pid, 'submitted'))

      Dor::WorkflowService.update_workflow_status 'dor', pid, 'versioningWF', 'submit-version', 'completed'
      # TODO setting start-accession to completed could happen later if we have a universal robot to kick of accessioning across workflows,
      # or if there's a review step after versioning is closed
      Dor::WorkflowService.update_workflow_status 'dor', pid, 'versioningWF', 'start-accession', 'completed'
      Dor::WorkflowService.archive_workflow 'dor', pid, 'versioningWF', opts[:version_num]
      initialize_workflow 'accessionWF' if(opts[:start_accession].nil? || opts[:start_accession])
    end

    # @return [Boolean] true if 'opened' lifecycle is active, false otherwise
    def new_version_open?
      return true if(Dor::WorkflowService.get_active_lifecycle('dor', pid, 'opened'))
      false
    end

    # Following chart of processes on this consul page: https://consul.stanford.edu/display/chimera/Versioning+workflows
    alias_method :start_version,  :open_new_version
    alias_method :submit_version, :close_version

  end
end