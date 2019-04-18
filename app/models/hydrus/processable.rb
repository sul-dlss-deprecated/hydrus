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
    workflow_client.update_workflow_status(REPO, pid, Dor::Config.hydrus.app_workflow, step, status)
    workflows_content_is_stale
  end

  # Deletes an objects hydrus workflow.
  def delete_hydrus_workflow
    workflow_client.delete_workflow(REPO, pid, Dor::Config.hydrus.app_workflow)
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
    workflow_client.create_workflow_by_name(pid, Dor::Config.hydrus.app_workflow, version: current_version)
  end

  # Returns value of Dor::Config.hydrus.start_assembly_wf.
  # Wrapped in method to simplify testing stubs.
  def should_start_assembly_wf
    Dor::Config.hydrus.start_assembly_wf
  end

  # Returns true if the most recent version of the object has been accessioned.
  def is_accessioned
    # Basic tests:
    #   - Must be published before it can be accessioned.
    #   - For local development and automated testing, treat published as
    #     equivalent to accessioned.
    return false unless is_published
    return true if should_treat_as_accessioned

    # Return false unless has been accessioned at least once.
    # accessioned lifecyle is set in the last step in the accessionWF.
    return false unless workflow_client.lifecycle(REPO, pid, 'accessioned')

    # Return false if accessionWF has been started for most current version and there are there are any incomplete workflow steps.
    return false if workflow_client.active_lifecycle(REPO, pid, 'submitted')

    # Accessioned.
    true
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
