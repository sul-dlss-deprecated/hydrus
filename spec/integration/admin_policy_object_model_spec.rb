require 'spec_helper'

describe Hydrus::AdminPolicyObject do
  
  it "should be able to create an APO object, whose APO is the Ur-APO" do
    user = 'foo@bar.com'
    apo  = Hydrus::AdminPolicyObject.create(user)
    apo.should be_instance_of Hydrus::AdminPolicyObject
    apo.admin_policy_object_ids.should == [Dor::Config.ur_apo_druid]
    apo.delete
  end

end
