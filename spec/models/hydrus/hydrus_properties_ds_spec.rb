require 'spec_helper'

describe Hydrus::HydrusPropertiesDS, type: :model do

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
    expect(@dsdoc.term_values(:users_accepted_terms_of_deposit, :user)).to eq(["cardinal", "crimson", "cornellian", "mhamster"])
    expect(@dsdoc.term_values(:users_accepted_terms_of_deposit, :user, :date_accepted)).to eq(["2011-09-02T01:10:32Z", "2012-05-02T12:10:44Z", "2011-10-02T02:13:31Z", "2011-10-02T02:13:31Z"])
    expect(@dsdoc.term_values(:embargo_terms)).to eq(["1 year"])
    expect(@dsdoc.term_values(:embargo_option)).to eq(["varies"])
    expect(@dsdoc.term_values(:license_option)).to eq(["fixed"])
    expect(@dsdoc.term_values(:visibility_option)).to eq(["fixed"])
    expect(@dsdoc.term_values(:requires_human_approval)).to eq(["no"])
    expect(@dsdoc.term_values(:accepted_terms_of_deposit)).to eq(["false"])
    expect(@dsdoc.term_values(:item_type)).to eq(["dataset"])
    expect(@dsdoc.term_values(:object_status)).to eq(["draft"])
    expect(@dsdoc.term_values(:disapproval_reason)).to eq(["Idiota"])
    expect(@dsdoc.term_values(:submitted_for_publish_time)).to eq(["2011-09-03T00:00:00Z"])
    expect(@dsdoc.term_values(:initial_submitted_for_publish_time)).to eq(["2011-09-03T00:00:11Z"])
    expect(@dsdoc.term_values(:initial_publish_time)).to eq(["2011-09-08T02:00:11Z"])
    expect(@dsdoc.term_values(:submit_for_approval_time)).to eq(["2011-08-03T00:00:00Z"])
    expect(@dsdoc.term_values(:last_modify_time)).to eq(["2011-09-02T00:00:00Z"])
    expect(@dsdoc.term_values(:version_started_time)).to eq(["2011-09-01T00:00:00Z"])
    expect(@dsdoc.term_values(:object_version)).to eq(["1999.01.01a"])
  end

  it "the blank template should match our expectations" do
    dsdoc = Hydrus::HydrusPropertiesDS.new(nil, nil)
    expect(dsdoc.ng_xml).to be_equivalent_to '<hydrusProperties></hydrusProperties>'
  end

  it "accept_terms_of_deposit() should add new user nodes or modify date, as appropriate" do
    @exp_xml = noko_doc <<-EOF
      <hydrusProperties>
        <usersAcceptedTermsOfDeposit>
          <user dateAccepted="10-02-2012 00:00:33">foo</user>
          <user dateAccepted="10-02-2012 00:00:44">bar</user>
        </usersAcceptedTermsOfDeposit>
      </hydrusProperties>
    EOF
    @dsdoc = Hydrus::HydrusPropertiesDS.new(nil, nil)
    @dsdoc.accept_terms_of_deposit('foo','10-02-2012 00:00:00') # First user.
    @dsdoc.accept_terms_of_deposit('bar','10-02-2012 00:00:44') # Second user.
    @dsdoc.accept_terms_of_deposit('foo','10-02-2012 00:00:33') # First user, new date.
    expect(@dsdoc.ng_xml).to be_equivalent_to @exp_xml
  end

end
