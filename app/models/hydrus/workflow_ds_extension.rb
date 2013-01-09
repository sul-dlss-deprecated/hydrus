module Hydrus::WorkflowDsExtension
end

class Dor::WorkflowDs

  # Note: unit tests are in generic_object_spec.rb.

  # Returns the hydrusAssemblyWF node from the object's workflows.
  def get_workflow_node
    wf = Dor::Config.hydrus.app_workflow
    q = "//workflow[@id='#{wf}']"
    return ng_xml.at_xpath(q)
  end

  # Takes the name of a hydrusAssemblyWF step.
  # Returns the corresponding process node.
  def get_workflow_step(step)
    node = get_workflow_node()
    return node ? node.at_xpath("//process[@name='#{step}']") : nil
  end

  # Takes the name of a hydrusAssemblyWF step.
  # Returns the staus of the corresponding process node.
  def get_workflow_status(step)
    node = get_workflow_step(step)
    return node ? node['status'] : nil
  end

  # Takes the name of a hydrusAssemblyWF step.
  # Returns the staus of the corresponding process node.
  def workflow_step_is_done(step)
    return get_workflow_status(step) == 'completed'
  end

end
