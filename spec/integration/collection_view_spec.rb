require 'spec_helper'

describe("Collection view", :type => :request) do
  fixtures :users

  before :each do
    @apo_druid = 'druid:oo000oo0002'
    @druid = 'druid:oo000oo0003'
    @hc    = Hydrus::Collection.find @druid
  end

  it "If not logged in, should be redirected to sign-in page" do
    logout
    visit polymorphic_url(@hc)
    current_path.should == new_user_session_path
  end

  it "Some of the expected info is displayed" do
    exp_content = [
      "SSDS Social Science Data Collection",
      "Description",
      "How Couples Meet and Stay Together",
      "Ethnic Collective Action",
    ]
    login_as_archivist1
    visit polymorphic_path(@hc)
    current_path.should == polymorphic_path(@hc)
    exp_content.each do |exp|
      page.should have_content(exp)
    end
  end

end
