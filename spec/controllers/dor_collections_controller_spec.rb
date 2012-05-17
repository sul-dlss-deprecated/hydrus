require 'spec_helper'

describe DorCollectionsController do

  describe "show action" do

    before(:each) do
      @pid = 'druid:sw909tc7852'
    end

    it "should get fedora document and assign various attributes", :integration => true do
      get :show, :id => @pid
      assigns[:pid].should_not be_nil
      assigns[:document_fedora].should_not be_nil
      assigns[:descMetadata].should_not be_nil
    end

  end

end
