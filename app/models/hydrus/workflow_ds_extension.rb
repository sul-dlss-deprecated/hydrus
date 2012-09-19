module Hydrus::WorkflowDsExtension
end

class Dor::WorkflowDs

  def to_solr(solr_doc = {}, *args)
    super(solr_doc, *args)
    status = workflow_step_is_done('approve') ? 'published' :
             workflow_step_is_done('submit')  ? 'waiting_approval' : 'draft'
    add_solr_value(
      solr_doc, 'hydrus_wf_status', status,
      :string, [:facetable, :searchable]
    )
    return solr_doc
  end

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
