require 'spec_helper'

describe("Item view", :type => :request) do

  before :each do
    @druid = 'druid:oo000oo0001'
    @hi    = Hydrus::Item.find @druid
  end

  it "Some of the expected info is displayed" do
    exp_items = [
      "How Couples Meet and Stay Together",
      "The story of Pinocchio",
      @druid,
      'Contributing Author',
      'Frisbee, Hanna',
      'Sponsor',
      'US National Science Foundation, award SES-0751613',
      'wooden boys',
      'Related content:',
      'Online survey research site (really Project Gutenberg)',
      'pinocchio.htm',
    ]
    visit polymorphic_url(@hi)
    exp_items.each do |exp|
      page.should have_content(exp)
    end
  end

end
