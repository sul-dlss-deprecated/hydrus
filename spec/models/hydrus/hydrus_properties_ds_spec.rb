require 'spec_helper'

describe Hydrus::HydrusPropertiesDS, :type => :model do

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
        <versionStartedTime>2011-09-01T00:00:00Z</versionStartedTime>
        <lastModifyTime>2011-09-02T00:00:00Z</lastModifyTime>
        <submitForApprovalTime>2011-08-03T00:00:00Z</submitForApprovalTime>
        <submittedForPublishTime>2011-09-03T00:00:00Z</submittedForPublishTime>
        <initialSubmittedForPublishTime>2011-09-03T00:00:11Z</initialSubmittedForPublishTime>
        <initialPublishTime>2011-09-08T02:00:11Z</initialPublishTime>
        <objectVersion>1999.01.01a</objectVersion>
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
      [:submitted_for_publish_time,  ["2011-09-03T00:00:00Z"]],
      [:initial_submitted_for_publish_time,  ["2011-09-03T00:00:11Z"]],
      [:initial_publish_time,  ["2011-09-08T02:00:11Z"]],
      [:submit_for_approval_time,  ["2011-08-03T00:00:00Z"]],
      [:last_modify_time,  ["2011-09-02T00:00:00Z"]],
      [:version_started_time,  ["2011-09-01T00:00:00Z"]],
      [:object_version,  ["1999.01.01a"]],
    ]
    tests.each do |terms, exp|
      expect(@dsdoc.term_values(*terms)).to eq(exp)
    end
  end

  it "the blank template should match our expectations" do
    exp_xml = %Q(
      #{@ds_start}
      #{@ds_end}
    )
    exp_xml = noko_doc(exp_xml)
    dsdoc = Hydrus::HydrusPropertiesDS.new(nil, nil)
    expect(dsdoc.ng_xml).to be_equivalent_to exp_xml
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
    expect(@dsdoc.ng_xml).to be_equivalent_to @exp_xml
  end

end
