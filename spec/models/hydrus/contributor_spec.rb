require 'spec_helper'

describe Hydrus::Contributor do

  before(:each) do
    @hc = Hydrus::Contributor.new(:name => 'Angus', :role => 'guitar')
  end

  it "default_contributor()" do
    @hc = Hydrus::Contributor.default_contributor
    @hc.should be_instance_of(Hydrus::Contributor)
    @hc.name.should == ''
    @hc.role.should == 'Author'
    @hc.name_type.should == 'personal'
    @hc.role_key.should == 'personal_author'
  end

  it "groups_for_select(): can exercise" do
    cgs = Hydrus::Contributor.groups_for_select
    cgs.should be_instance_of(Array)
    cgs.size.should == 3
  end

  it "lookup_with_role_key()" do
    tests = {
      'personal_author'               => ['personal', 'Author'],
      'corporate_author'              => ['corporate', 'Author'],
      'corporate_contributing_author' => ['corporate', 'Contributing author'],
      'conference_conference'         => ['conference', 'Conference'],
      'blah blah'                     => ['personal', 'Author'],
    }
    tests.each do |role_key, exp|
      Hydrus::Contributor.lookup_with_role_key(role_key).should == exp
    end

  end

end
