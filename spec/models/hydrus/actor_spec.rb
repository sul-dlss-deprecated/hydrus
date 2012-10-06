require 'spec_helper'

describe Hydrus::Actor do
  subject { Hydrus::Actor.new :name => 'Angus', :role => 'guitar' }

  it "should have a #name accessor" do
    subject.name.should == "Angus"
  end

  it "should have a role accessor" do
    subject.role.should == "guitar"
  end
end
