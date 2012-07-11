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
      #{@amd_end}
    EOF
    @amdoc = Hydrus::AdministrativeMetadataDS.from_xml(xml)
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

end
