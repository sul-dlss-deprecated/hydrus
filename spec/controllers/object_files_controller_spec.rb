# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ObjectFilesController do

  describe "file upload" do
    before(:each) do
      @filename="/../../spec/fixtures/files/fixture.html"
      @pid = "druid:oo000oo0001"
      @binary_data = Base64.encode64(File.open(fixture_file_upload(@filename, "text/html").path, "r").read)
      @name = "fixture.html"
    end
    
    def cleanup(file)
      Hydrus::ObjectFile.find(file.id).destroy
    end
    
    describe "create" do
      it "should create Hydrus::Object files from binary data" do
        controller.stub(:current_user).and_return(mock_authed_user)
        post :create, :id => @pid, :binary_data => @binary_data, :file_name => @name, :format => "js"
        response.should be_success
        file = assigns(:file)
        file.is_a?(Hydrus::ObjectFile).should be_true
        file.pid.should == @pid
        file.filename.should == @name
        File.exists?(file.current_path).should == true    
        cleanup file    
      end
    end
    describe "destroy" do
        it "should delete a Hydrus::Object file and remove the file itself when destroy method is called" do
          controller.stub(:current_user).and_return(mock_authed_user)
          post :create, :id => @pid, :binary_data => @binary_data, :file_name => @name, :format => "js"
          response.should be_success
          file = assigns(:file)
          File.exists?(file.current_path).should == true
          post :destroy, :id => file.id, :format => "js"
          File.exists?(file.current_path).should == false
          Hydrus::ObjectFile.find_by_id(file.id).should == nil 
        end
      end
  end

end
