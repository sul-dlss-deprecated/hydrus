require 'spec_helper'

describe Hydrus::HydrusPropertiesDS do

  before(:all) do
    @ds_start="<hydrusProperties>"
    @ds_end="</hydrusProperties>"
    xml = <<-EOF
      #{@ds_start}
        <acceptedTermsOfDeposit>true</acceptedTermsOfDeposit>
        <requiresHumanApproval>no</requiresHumanApproval>
        <disapprovalReason>Idiota</disapprovalReason>
      #{@ds_end}
    EOF
    @dsdoc = Hydrus::HydrusPropertiesDS.from_xml(xml)
  end
  
  it "should get expected values from OM terminology" do
    tests = [
      [:accepted_terms_of_deposit, ["true"]],
      [:requires_human_approval, ["no"]],
      [:disapproval_reason, ["Idiota"]],
    ]
    tests.each do |terms, exp|
      @dsdoc.term_values(*terms).should == exp
    end
  end

  it "the blank template should match our expectations" do
    exp_xml = %Q(
      #{@ds_start}
      #{@ds_end}
    )
    exp_xml = noko_doc(exp_xml)
    dsdoc = Hydrus::HydrusPropertiesDS.new(nil, nil)
    dsdoc.ng_xml.should be_equivalent_to exp_xml
  end

end
