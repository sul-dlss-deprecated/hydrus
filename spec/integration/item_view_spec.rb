require 'spec_helper'

describe("Item view", :type => :request) do
  fixtures :users

  before :each do
    @druid = 'druid:oo000oo0001'
    @hi    = Hydrus::Item.find @druid
  end

  it "If not logged in, should be redirected to sign-in page" do
    logout
    visit polymorphic_url(@hi)
    current_path.should == new_user_session_path
  end

  it "Some of the expected info is displayed" do
    exp_content = [
      "How Couples Meet and Stay Together", # title
      "The story of Pinocchio", #abstract
      @druid,
      'Contributing Author', # label for actor
      'Frisbee, Hanna', # actor
      'Sponsor', # label for actor 
      'US National Science Foundation, award SES-0751613', # actor
      'wooden boys', # keyword
      'Related content', # relatedItem label
      'Reuters Newswire: Being Online can Boost', # relatedItem title
      'pinocchio.htm', # file
    ]
    login_as_archivist1
    visit polymorphic_path(@hi)
    current_path.should == polymorphic_path(@hi)
    exp_content.each do |exp|
      page.should have_content(exp)
    end
  end

end
