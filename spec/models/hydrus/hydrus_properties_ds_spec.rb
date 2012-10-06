require 'spec_helper'

describe Hydrus::HydrusPropertiesDS do

  before(:all) do
    @ds_start="<hydrusProperties>"
    @ds_end="</hydrusProperties>"
    xml = <<-EOF
      #{@ds_start}
        <usersAcceptedTermsOfDeposit>
  	    	<user dateAccepted="2011-09-02 01:02:32 -0700">cardinal</user>
        	<user dateAccepted="2012-05-02 12:02:44 -0700">crimson</user>
        	<user dateAccepted="2011-10-02 02:05:31 -0700">cornellian</user>
        	<user dateAccepted="2011-10-02 02:05:31 -0700">mhamster</user>
        </usersAcceptedTermsOfDeposit>
        <requiresHumanApproval>no</requiresHumanApproval>
        <acceptedTermsOfDeposit>false</acceptedTermsOfDeposit>
        <disapprovalReason>Idiota</disapprovalReason>
      #{@ds_end}
    EOF
    @dsdoc = Hydrus::HydrusPropertiesDS.from_xml(xml)
  end
  
  it "should get expected values from OM terminology" do
    tests = [
      [[:users_accepted_terms_of_deposit,:user],%w{cardinal crimson cornellian mhamster}],
      [[:users_accepted_terms_of_deposit,:user,:date_accepted],["2011-09-02 01:02:32 -0700","2012-05-02 12:02:44 -0700","2011-10-02 02:05:31 -0700","2011-10-02 02:05:31 -0700"]],
      [:requires_human_approval, ["no"]],
      [:accepted_terms_of_deposit, ["false"]],
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

  it "should be able to add a user who accepted the terms of deposit to the collection" do
      user_node = '<usersAcceptedTermsOfDeposit><user dateAccepted="10-02-2012 00:00:00">foo</user></usersAcceptedTermsOfDeposit>'
      @exp_xml = noko_doc([
        @ds_start,
        user_node,
        @ds_end,
      ].join '')
      @dsdoc   = Hydrus::HydrusPropertiesDS.from_xml("#{@ds_start}#{@ds_end}")
     @dsdoc.insert_user_accepting_terms_of_deposit('foo','10-02-2012 00:00:00')
     @dsdoc.ng_xml.should be_equivalent_to @exp_xml
  end
  
end
