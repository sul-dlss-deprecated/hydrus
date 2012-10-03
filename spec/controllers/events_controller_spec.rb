require 'spec_helper'

describe EventsController do

  it "should restrict access to users who shouldn't be able to view items" do
    controller.stub(:current_user).and_return(mock_user)
    get :index
    flash[:error].should =~ /You do not have sufficient privileges to read that document/
    response.should redirect_to(root_path)
  end

  it "should assign the given object for the given ID as the document_fedora instance variable" do
    controller.stub(:current_user).and_return(mock_authed_user)
    mock_coll = mock("HydrusCollection", :hydrus_class_to_s => 'Collection')
    mock_coll.should_receive(:"current_user=").and_return("")
    ActiveFedora::Base.stub(:find).and_return(mock_coll)
    controller.stub(:'can?').and_return(true)
    get :index, :hydrus_collection_id=>"1234"
    response.should be_success
    assigns(:document_fedora).should == mock_coll
  end

end
