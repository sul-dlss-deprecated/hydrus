# A mixin for workflow stuff.

module Hydrus::Processable

  # Takes the name of a step in the Hydrus workflow.
  # Calls the workflow service to mark that step as completed.
  def complete_workflow_step(step)
    return if workflows.workflow_step_is_done(step)
    update_workflow_status(step, 'completed')
  end

  # Marks all steps in the hydrusAssemblyWF (except the first) as waiting.
  # This occurs when the user opens a new version of an Item.
  def uncomplete_workflow_steps
    steps = Dor::Config.hydrus.app_workflow_steps[1..-1]
    steps.each { |s| update_workflow_status(s, 'waiting') }
  end

  # Takes the name of a step in the Hydrus workflow.
  # Calls the workflow service to mark that step as completed.
  def update_workflow_status(step, status)
    awf = Dor::Config.hydrus.app_workflow
    Dor::WorkflowService.update_workflow_status('dor', pid, awf, step, status)
    workflows_content_is_stale
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
    update_content_metadata
    complete_workflow_step('start-assembly')
    start_assembly_wf
  end

  # Kicks off a Hydrus-specific variant of assemblyWF -- one that skips
  # the creation of derivative files (JP2s, etc). This method is normally
  # configured to be a no-op during local development and the running of
  # automated tests.
  def start_assembly_wf
    return unless should_start_assembly_wf
    xml = Dor::Config.hydrus.assembly_wf_xml
    Dor::WorkflowService.create_workflow('dor', pid, 'assemblyWF', xml)
  end

  # Returns value of Dor::Config.hydrus.start_assembly_wf.
  # Wrapped in method to simplify testing stubs.
  def should_start_assembly_wf
    return Dor::Config.hydrus.start_assembly_wf
  end

  # Returns true if the most recent version of the object has been accessioned.
  def is_accessioned
    # Basic tests:
    #   - Must be published before it can be accessioned.
    #   - For local development and automated testing, treat published as
    #     equivalent to accessioned.

    return false unless is_published
    return true if should_treat_as_accessioned

    # During the assembly-accessioning process, an object is assembled, then
    # the object is accessioned, and finally (during a nightly cron job) the
    # workflow-archiver moves the object's workflow lifecycle rows from the
    # "active" table to the "archive" table in the workflow service's DB.
    #
    # Here are the lifecycle milestones we need to consider:
    #
    #   assemblyWF  start     pipelined
    #   accessionWF start     submitted
    #   accessionWF end       accessioned

    wfs = Dor::WorkflowService
    p   = pid()

    # Never accessioned.
    # This query check both active and archived rows.
    return false unless wfs.get_lifecycle('dor', p, 'accessioned')

    # Actively in the middle of assemblyWF or accessionWF.
    # We don't want to treat an object as fully accessioned until
    # the robots are finished and the archiver has run.
    return false if wfs.get_active_lifecycle('dor', p, 'pipelined')
    return false if wfs.get_active_lifecycle('dor', p, 'submitted')

    # Accessioned and archived.
    return true
  end

  # Returns true if we are running in development or test mode.
  # In a method to facilitate unit testing of is_accessioned().
  def should_treat_as_accessioned
    return %w(development test).include?(Rails.env)
  end

end