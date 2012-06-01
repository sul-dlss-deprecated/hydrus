# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ObjectFilesController do

  describe "file upload" do
    describe "create" do
      before(:all) do
        @pid = "druid:oo000oo0001"
        @binary_data = Base64.encode64(File.open(fixture_file_upload("/../../spec/fixtures/files/fixture.html", "text/html").path, "r").read)
        @name = "fixture.html"
      end
      it "should create Hydrus::Object files from binary data" do
        controller.stub(:current_user).and_return(mock_authed_user)
        post :create, :id => @pid, :binary_data => @binary_data, :file_name => @name, :format => "js"
        response.should be_success
        file = assigns(:file)
        file.is_a?(Hydrus::ObjectFile).should be_true
        file.pid.should == @pid
        file.filename.should == @name
      end
    end
  end

end
