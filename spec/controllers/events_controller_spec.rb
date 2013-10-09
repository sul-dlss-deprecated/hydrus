require 'spec_helper'

describe EventsController do

  before :each do
    @ability = Object.new
    @ability.extend(CanCan::Ability)
    controller.stub(:current_ability => @ability)
  end


  it "should require login" do
    get :index, :hydrus_collection_id => "1234"
    flash[:alert].should == "You need to sign in or sign up before continuing."
    response.should redirect_to(new_user_session_path)
  end

context "as an authenticated user" do
  before :each do
    sign_in(mock_authed_user)
  end

  it "should restrict access to users who shouldn't be able to view items" do  
    mock_coll = double("HydrusCollection", :hydrus_class_to_s => 'Collection')
    mock_coll.should_receive(:"current_user=")
    ActiveFedora::Base.stub(:find).and_return(mock_coll)
    @ability.cannot :read, mock_coll

    get :index, :hydrus_collection_id => "1234"
    
    flash[:alert].should == "You are not authorized to access this page."
    response.should redirect_to(root_path)
  end

  it "should assign the given object for the given ID as the fobj instance variable" do

    mock_coll = double("HydrusCollection", :hydrus_class_to_s => 'Collection')
    mock_coll.should_receive(:"current_user=")
    ActiveFedora::Base.stub(:find).and_return(mock_coll)
    @ability.can :read, mock_coll

    get :index, :hydrus_collection_id=>"1234"
    
    response.should be_success
    assigns(:fobj).should == mock_coll
  end
end

end
