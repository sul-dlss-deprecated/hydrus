require 'spec_helper'

describe Hydrus::AdminPolicyObject do
  
  it "should be able to create an APO object, whose APO is the Ur-APO" do
    # Create an APO.
    user = 'foo@bar.com'
    apo  = Hydrus::AdminPolicyObject.create(user)
    # Should be an APO whose APO is the ur-APO.
    apo.should be_instance_of Hydrus::AdminPolicyObject
    apo.admin_policy_object_ids.should == [Dor::Config.ur_apo_druid]
    # Should have some hydrusAssemblyWF steps.
    steps = apo.administrativeMetadata.hydrusAssembly.workflow.process.name
    steps.size.should > 0
  end

end
