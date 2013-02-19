require 'spec_helper'

describe Hydrus::Contributor do
  subject { Hydrus::Contributor.new :name => 'Angus', :role => 'guitar' }

  it "should have a #name accessor" do
    subject.name.should == "Angus"
  end

  it "should have a role accessor" do
    subject.role.should == "guitar"
  end
end
