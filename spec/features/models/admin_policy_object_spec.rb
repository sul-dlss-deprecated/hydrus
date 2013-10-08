require 'spec_helper'

describe(Hydrus::AdminPolicyObject, :integration => true) do

  it "should be able to create an APO object, whose APO is the Ur-APO" do
    # Create an APO.
    Dor::SuriService.stub(:mint_id).and_return 'druid:oo000oo1234'
    Dor::WorkflowDs.any_instance.stub(:current_priority).and_return 0
    user = 'foo@bar.com'
    apo  = Hydrus::AdminPolicyObject.create(user)
    # Should be an APO whose APO is the ur-APO.
    expect(apo).to_not be_new
    apo.should be_instance_of Hydrus::AdminPolicyObject
    expect(apo.admin_policy_object.pid).to eq Dor::Config.hydrus.ur_apo_druid
    expect(apo.title).to eq Dor::Config.hydrus.initial_apo_title
    expect(apo.label).to eq apo.title
    expect(apo.roleMetadata).to_not be_new
    expect(apo.roleMetadata.collection_manager).to include user
    expect(apo.roleMetadata.collection_depositor).to include user

    expect(apo.defaultObjectRights).to_not be_new
    expect(apo.relationships(:references_agreement)).to include "info:fedora/druid:mc322hh4254"

  end

end
