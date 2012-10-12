require 'spec_helper'

describe(ApplicationHelper, :type => :request, :integration=>true) do

  include ApplicationHelper
  
  it "should show correct view_item_text" do    
    login_as_archivist1
    hc=Hydrus::Item.find('druid:oo000oo0001')
    view_item_text(hc).should == 'Published Version'
    hi=Hydrus::Item.new
    view_item_text(hi).should == 'View Draft'
  end  

end