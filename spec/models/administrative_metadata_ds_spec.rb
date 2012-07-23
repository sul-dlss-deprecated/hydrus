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

  it "insert_hydrus_assembly_wf() should add workflow info to the APO" do
    # Create an empty doc.
    xml = "#{@amd_start}#{@amd_end}"
    @amdoc = Hydrus::AdministrativeMetadataDS.from_xml(noko_doc(xml))
    # Should have no workflow steps yet.
    @amdoc.hydrusAssembly.workflow.process.name.should == []
    # Insert the hydrusAssemblyWF, and check for workflow steps.
    @amdoc.insert_hydrus_assembly_wf
    exp = Dor::Config.hydrus_assembly_wf_steps.map { |s| s[:name] }
    @amdoc.hydrusAssembly.workflow.process.name.should == exp
  end

end
