require 'spec_helper'

describe Hydrus::Contributor, :type => :model do

  before(:each) do
    @hc = Hydrus::Contributor.new(:name => 'Angus', :role => 'guitar')
  end

  it "default_contributor()" do
    @hc = Hydrus::Contributor.default_contributor
    expect(@hc).to be_instance_of(Hydrus::Contributor)
    expect(@hc.name).to eq('')
    expect(@hc.role).to eq('Author')
    expect(@hc.name_type).to eq('personal')
    expect(@hc.role_key).to eq('personal_author')
  end

  it "groups_for_select(): can exercise" do
    cgs = Hydrus::Contributor.groups_for_select
    expect(cgs).to be_instance_of(Array)
    expect(cgs.size).to eq(3)
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
      expect(Hydrus::Contributor.lookup_with_role_key(role_key)).to eq(exp)
    end

  end

  it "clone() and ==()" do
    # Create two clones.
    c1 = Hydrus::Contributor.default_contributor
    c1.name = 'Los Pollos Hermanos'
    c2 = c1.clone
    # Should be equal but not the same object.
    expect(c1).to eq(c2)
    expect(c1.object_id).not_to eq(c2.object_id)
    # Should be unequal if any single attribute differs.
    [:name, :role, :name_type].each do |getter|
      setter   = "#{getter}="
      orig_val = c2.send(getter)
      c2.send(setter, 'foobar')
      expect(c1).not_to eq(c2)
      c2.send(setter, orig_val)
      expect(c1).to eq(c2)
    end
  end

end
