require 'spec_helper'

describe CatalogController do

  it "should show the home page" do
    controller.stub(:current_user).and_return(mock_user)
    get :index
    @collections.should_not be nil
  end

  it "should indicate if we have search parameters" do
    @params={:q=>'some query'}
    has_search_parameters?.should be true
  end

  it "should indicate if we don't have search parameters" do
    @params={}
    has_search_parameters?.should be false
  end

end