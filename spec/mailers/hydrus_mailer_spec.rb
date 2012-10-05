require 'spec_helper'

describe HydrusMailer do
  
  before(:all) do
    @fedora_document = OpenStruct.new
    @fedora_document.title = "Collection Title"
    @fedora_document.owner = "jdoe"
  end
  
  describe "open notification" do
    before(:all) do
      @mail = HydrusMailer.open_notification(:to => "jdoe1, jdoe2", :object => @fedora_document)
    end
    it "should have the correct subject" do
      @mail.subject.should == "Collection opened for deposit in the Stanford Digital Repository"
    end
    it "should have the correct recipients" do
      ["jdoe1@stanford.edu", "jdoe2@stanford.edu"].each do |address|
        @mail.to.should include(address)
      end
    end
    it "should have the correct text in the body" do
      body = Capybara.string(@mail.body.to_s)
      body.should have_content("jdoe has opened the Collection Title collection for deposit")
    end
  end
  
  describe "close notification" do
    before(:all) do
      @mail = HydrusMailer.close_notification(:to => "jdoe1, jdoe2", :object => @fedora_document)
    end
    it "should have the correct subject" do
      @mail.subject.should == "Collection closed for deposit in the Stanford Digital Repository"
    end
    it "should have the correct recipients" do
      ["jdoe1@stanford.edu", "jdoe2@stanford.edu"].each do |address|
        @mail.to.should include(address)
      end
    end
    it "should have the correct text in the body" do
      body = Capybara.string(@mail.body.to_s)
      body.should have_content("jdoe has closed the Collection Title collection")
    end
  end
  
  describe "invitation" do
    before(:all) do
      @mail = HydrusMailer.invitation(:to => "jdoe1, jdoe2", :object => @fedora_document)
    end
    it "should have the correct subject" do
      @mail.subject.should == "Invitation to deposit in the Stanford Digital Repository"
    end
    it "should have the correct recipients" do
      ["jdoe1@stanford.edu", "jdoe2@stanford.edu"].each do |address|
        @mail.to.should include(address)
      end
    end
    it "should have the correct text in the body" do
      body = Capybara.string(@mail.body.to_s)
      body.should have_content("jdoe has invited you to deposit into the Collection Title collection")
    end
  end
  
  describe "private methods" do
    
    describe "process user list" do
      it "should turn all user strings into email addresses" do
        HydrusMailer.process_user_list("jdoe1, jdoe2,jdoe3,  jdoe4 ").should == ["jdoe1@stanford.edu", "jdoe2@stanford.edu", "jdoe3@stanford.edu", "jdoe4@stanford.edu"]
      end
      it "should not attempt to put @stanford.edu at the end of email addresses" do
        HydrusMailer.process_user_list("jdoe1, archivist1@example.com,jdoe2").should == ["jdoe1@stanford.edu", "archivist1@example.com", "jdoe2@stanford.edu"]
      end
    end
    
  end
  
end