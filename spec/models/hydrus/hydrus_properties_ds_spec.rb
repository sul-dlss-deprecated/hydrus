require 'spec_helper'

describe Hydrus::HydrusPropertiesDS do

  before(:all) do
    @ds_start="<hydrusProperties>"
    @ds_end="</hydrusProperties>"
    xml = <<-EOF
      #{@ds_start}
        <usersAcceptedTermsOfDeposit>
          <user dateAccepted="2011-09-02T01:10:32Z">cardinal</user>
          <user dateAccepted="2012-05-02T12:10:44Z">crimson</user>
          <user dateAccepted="2011-10-02T02:13:31Z">cornellian</user>
          <user dateAccepted="2011-10-02T02:13:31Z">mhamster</user>
        </usersAcceptedTermsOfDeposit>
        <embargoTerms>1 year</embargoTerms>
        <embargoOption>varies</embargoOption>
        <licenseOption>fixed</licenseOption>
        <visibilityOption>fixed</visibilityOption>
        <requiresHumanApproval>no</requiresHumanApproval>
        <acceptedTermsOfDeposit>false</acceptedTermsOfDeposit>
        <itemType>dataset</itemType>
        <objectStatus>draft</objectStatus>
        <disapprovalReason>Idiota</disapprovalReason>
        <publishTime>2011-09-03T00:00:00Z</publishTime>
        <submitForApprovalTime>2011-08-03T00:00:00Z</submitForApprovalTime>
        <lastModifyTime>2011-09-02T00:00:00Z</lastModifyTime>
      #{@ds_end}
    EOF
    @dsdoc = Hydrus::HydrusPropertiesDS.from_xml(xml)
  end

  it "should get expected values from OM terminology" do
    exp_dts = [
      "2011-09-02T01:10:32Z",
      "2012-05-02T12:10:44Z",
      "2011-10-02T02:13:31Z",
      "2011-10-02T02:13:31Z",
    ]
    tests = [
      [[:users_accepted_terms_of_deposit,:user],%w{cardinal crimson cornellian mhamster}],
      [[:users_accepted_terms_of_deposit,:user,:date_accepted], exp_dts],
      [:embargo_terms, ["1 year"]],
      [:embargo_option, ["varies"]],
      [:license_option, ["fixed"]],
      [:visibility_option, ["fixed"]],
      [:requires_human_approval, ["no"]],
      [:accepted_terms_of_deposit, ["false"]],
      [:item_type, ["dataset"]],
      [:object_status, ["draft"]],
      [:disapproval_reason, ["Idiota"]],
      [:publish_time,  ["2011-09-03T00:00:00Z"]],
      [:submit_for_approval_time,  ["2011-08-03T00:00:00Z"]],
      [:last_modify_time,  ["2011-09-02T00:00:00Z"]],
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

  it "accept_terms_of_deposit() should add new user nodes or modify date, as appropriate" do
    k = 'usersAcceptedTermsOfDeposit'
    u1 = '<user dateAccepted="10-02-2012 00:00:33">foo</user>'
    u2 = '<user dateAccepted="10-02-2012 00:00:44">bar</user>'
    @exp_xml = noko_doc([
      @ds_start,
      "<#{k}>#{u1}#{u2}</#{k}>",
      @ds_end,
    ].join '')
    @dsdoc = Hydrus::HydrusPropertiesDS.from_xml("#{@ds_start}#{@ds_end}")
    @dsdoc.accept_terms_of_deposit('foo','10-02-2012 00:00:00') # First user.
    @dsdoc.accept_terms_of_deposit('bar','10-02-2012 00:00:44') # Second user.
    @dsdoc.accept_terms_of_deposit('foo','10-02-2012 00:00:33') # First user, new date.
    @dsdoc.ng_xml.should be_equivalent_to @exp_xml
  end

end
