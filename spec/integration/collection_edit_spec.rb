require 'spec_helper'

describe("Collection edit", :type => :request) do
  fixtures :users

  before :each do
    @druid = 'druid:oo000oo0003'
    @hc    = Hydrus::Collection.find @druid
  end

  it "If not logged in, should be redirected to sign-in page" do
    logout
    visit edit_polymorphic_path(@hc)
    current_path.should == new_user_session_path
  end

  it "Can edit some Collection content" do
    new_abstract  = 'foobarfubb'
    orig_abstract = @hc.descMetadata.abstract.first

    login_as_archivist1

    visit edit_polymorphic_path(@hc)
    current_path.should == edit_polymorphic_path(@hc)

    page.should have_content(orig_abstract)
    page.should_not have_content(new_abstract)
    fill_in "Abstract", :with => new_abstract
    click_button "Save"

    current_path.should == polymorphic_path(@hc)
    visit polymorphic_path(@hc)
    page.should have_content(new_abstract)

    # Clean up.
    visit edit_polymorphic_path(@hc)
    current_path.should == edit_polymorphic_path(@hc)
    fill_in "Abstract", :with => orig_abstract
    click_button "Save"
  end

end
