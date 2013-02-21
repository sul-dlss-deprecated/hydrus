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

  it "clone() and ==()" do
    # Create two clones.
    c1 = Hydrus::Contributor.default_contributor
    c1.name = 'Los Pollos Hermanos'
    c2 = c1.clone
    # Should be equal but not the same object.
    c1.should == c2
    c1.object_id.should_not == c2.object_id
    # Should be unequal if any single attribute differs.
    [:name, :role, :name_type].each do |getter|
      setter   = "#{getter}="
      orig_val = c2.send(getter)
      c2.send(setter, 'foobar')
      c1.should_not == c2
      c2.send(setter, orig_val)
      c1.should == c2
    end
  end

end
