# A mixin for workflow stuff.

module Hydrus::Processable
  REPO = 'dor'

  def workflow_client
    Dor::Config.workflow.client
  end

  # Takes the name of a step in the Hydrus workflow.
  # Calls the workflow service to mark that step as completed.
  def complete_workflow_step(step)
    update_workflow_status(step, 'completed')
  end

  # Takes the name of a step in the Hydrus workflow.
  # Calls the workflow service to mark that step as completed.
  def update_workflow_status(step, status)
    workflow_client.update_status(druid: pid,
                                  workflow: Settings.hydrus.app_workflow,
                                  process: step,
                                  status: status)
    workflows_content_is_stale
  end

  # Deletes an objects hydrus workflow.
  def delete_hydrus_workflow
    workflow_client.delete_workflow(REPO, pid, Settings.hydrus.app_workflow)
  end

  # Resets two instance variables of the workflow datastream. By resorting to
  # this encapsulation-violating hack, we ensure that our current Hydrus object
  # will not rely on its cached copy of the workflow XML. Instead it will call
  # to the workflow service to get the latest XML, particularly during the
  # save() process, which is when our object will be resolarized.
  def workflows_content_is_stale
    %w(@content @ng_xml).each { |v| workflows.instance_variable_set(v, nil) }
  end

  # Generates the object's contentMetadata, finalizes the hydrusAssemblyWF
  # workflow, and then kicks off the assembly and accessioning pipeline.
  def start_common_assembly
    cannot_do(:start_common_assembly) unless is_assemblable()
    delete_missing_files if is_item?
    create_druid_tree
    update_content_metadata if is_item?
    complete_workflow_step('start-assembly')
    start_assembly_wf
  end

  # Kicks off assemblyWF
  # This method is normally configured to be a no-op during local development and the running of
  # automated tests.
  def start_assembly_wf
    return unless should_start_assembly_wf
    workflow_client.create_workflow_by_name(pid, 'assemblyWF', version: current_version)
  end

  # Kicks off hydrusAssemblyWF
  def start_hydrus_wf
    workflow_client.create_workflow_by_name(pid, Settings.hydrus.app_workflow, version: current_version)
  end

  # Returns value of Settings.hydrus.start_assembly_wf.
  # Wrapped in method to simplify testing stubs.
  def should_start_assembly_wf
    Settings.hydrus.start_assembly_wf
  end

  # Returns true if a new version can be opened for the object.
  def version_openable?
    return false unless is_published
    # For testing, this avoids Dor::Services::Client.
    return false if should_treat_as_accessioned
    Dor::Services::Client.object(pid).version.openable?(assume_accessioned: should_treat_as_accessioned)
  end

  # Returns a string -- the datetime when the object achived the published
  # lifecycle in common accessioning.
  def publish_time
    pt = if should_treat_as_accessioned
           # In development and test mode, simulated a publish_time of 1 day later.
           submitted_for_publish_time.to_datetime + 1.day
         else
           workflow_client.lifecycle(REPO, pid, 'published')
         end
    HyTime.datetime(pt)
  end

  # Returns true if we are running in development or test mode.
  def should_treat_as_accessioned
    %w(development test).include?(Rails.env)
  end
end
