require 'spec_helper'

describe Hydrus::AdministrativeMetadataDS do

  before(:all) do
    @amd_start = '<administrativeMetadata>'
    @amd_end   = '</administrativeMetadata>'
  end

  before(:each) do
    xml = <<-EOF
      #{@amd_start}
        <relationships />
        <hydrus>
          <depositStatus>open</depositStatus>
          <reviewRequired>yes</reviewRequired>
          <termsOfDeposit>Blah-blah</termsOfDeposit>
          <embargo option="varies">1-year</embargo>
          <visibility option="fixed">stanford</visibility>
          <license option="fixed">cc-by</license>
        </hydrus>
        <hydrusAssembly>
          <workflow id="hydrusAssemblyWF">
            <process name="start-deposit" status="completed" lifecycle="registered"/>
            <process name="submit" status="waiting"/>
          </workflow>
        </hydrusAssembly>
        <assembly>
          <workflow id="assemblyWF">
            <process name="start-assembly" status="completed" lifecycle="inprocess"/>
            <process name="checksum-compute" status="waiting"/>
          </workflow>
        </assembly>
        <accession>
          <workflow id="accessionWF">
            <process name="start-accession" status="completed" lifecycle="submitted"/>
            <process name="descriptive-metadata" status="waiting" lifecycle="described"/>
          </workflow>
        </accession>
      #{@amd_end}
    EOF
    @amdoc = Hydrus::AdministrativeMetadataDS.from_xml(noko_doc(xml))
  end

  it "should get expected values from OM terminology" do
    tests = [
      [[:hydrus, :depositStatus], %w(open)],
      [[:hydrus, :reviewRequired], %w(yes)],
      [[:hydrus, :termsOfDeposit], %w(Blah-blah)],
      [[:hydrus, :embargo], %w(1-year)],
      [[:hydrus, :embargo, :option], %w(varies)],
      [[:hydrus, :visibility, :option], %w(fixed)],
      [[:hydrus, :license, :option], %w(fixed)],
      [[:hydrusAssembly, :workflow, :process, :name], %w(start-deposit submit)],
      [[:hydrusAssembly, :workflow, :process, :status], %w(completed waiting)],
      [[:hydrusAssembly, :workflow, :process, :lifecycle], %w(registered)],
      [[:assembly,  :workflow, :process, :lifecycle], %w(inprocess)],
      [[:accession, :workflow, :process, :lifecycle], %w(submitted described)],
    ]
    tests.each do |terms, exp|
      @amdoc.term_values(*terms).should == exp
    end
  end

  it "the blank template should match our expectations" do
    exp_xml = %Q(
      #{@amd_start}
        <relationships/>
        <hydrus>
          <depositStatus/>
          <reviewRequired/>
          <termsOfDeposit/>
          <embargo/>
          <visibility/>
          <license/>
        </hydrus>
      #{@amd_end}
    )
    exp_xml = noko_doc(exp_xml)
    @amdoc = Hydrus::AdministrativeMetadataDS.new(nil, nil)
    @amdoc.ng_xml.should be_equivalent_to exp_xml
  end

  it "insert_workflow() should add workflow info to the APO" do
    # Create an empty doc.
    xml = "#{@amd_start}#{@amd_end}"
    @amdoc = Hydrus::AdministrativeMetadataDS.from_xml(noko_doc(xml))
    # Should have no workflow steps yet.
    @amdoc.hydrusAssembly.workflow.process.name.should == []
    # Insert the workflows, and check for the steps.
    Dor::Config.hydrus.workflow_steps.each do |wf_name, steps|
      @amdoc.insert_workflow(wf_name)
      exp = steps.map { |s| s[:name] }
      swf = Hydrus::AdministrativeMetadataDS.short_wf(wf_name)
      @amdoc.send(swf).workflow.process.name.should == exp
    end
  end

end
