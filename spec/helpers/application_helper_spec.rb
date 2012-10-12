require 'spec_helper'

describe ApplicationHelper do

  include ApplicationHelper
  
  # fake out some methods to make our tests pass
  def can?(action,item)
    return true
  end
  
  it "should show correct view_item_text" do    
    hi=Hydrus::Item.new
    hi.stub(:is_published).and_return(true)    
    view_item_text(hi).should == 'Published Version'
    hi.stub(:is_published).and_return(false)    
    view_item_text(hi).should == 'View Draft'
  end
  
  it "should get the local application name" do
    application_name.should == "Stanford Digital Repository"
  end

  it "should show the signin link" do
    controller.request.stub(:fullpath).and_return('/items/oo000oo0001')
    helper.hydrus_signin_link.should == "<a href=\"/signin/new?referrer=%2Fitems%2Foo000oo0001\" class=\"signin_link\" data-url=\"/signin/new?referrer=%2Fitems%2Foo000oo0001\">Sign in</a>"
  end
  
  it "should indicate if an object is empty" do
    hydrus_is_empty?(nil).should be true
    hydrus_is_empty?('').should be true
    hydrus_is_empty?(['','']).should be true
    hydrus_is_empty?(['',['']]).should be true
    hydrus_is_empty?(Hydrus::Actor.new).should be true
    hydrus_is_empty?(['',['stuff']]).should be false
    hydrus_is_empty?(['stuff']).should be false
    hydrus_is_empty?('stuff').should be false
    hydrus_is_empty?(Hydrus::Actor.new(:name=>'peter',:role=>'el jefe')).should be false
  end

  it "should show the item edit tab appropriately" do
    item=mock(Hydrus::Item)

    Rails.stub(:env).and_return('development')
    item.stub(:is_published).and_return(true)
    show_item_edit(item).should be true
    item.stub(:is_published).and_return(false)
    show_item_edit(item).should be true

    Rails.stub(:env).and_return('production')
    item.stub(:is_published).and_return(true)
    show_item_edit(item).should be false
    item.stub(:is_published).and_return(false)
    show_item_edit(item).should be true
  end
  
  it "should render the correct contextual layout" do
    controller=mock(HydrusCollectionsController)
    render_contextual_layout.should == "<ul class=\"breadcrumb\">\n  <li><a href=\"/\">Home</a></li>\n</ul>\n\n\n<div class=\"row\">\n  <div class=\"span9\" id=\"main\"></div>\n  <div class=\"span3\" id=\"sidebar\"></div>\n</div>\n"
  end
  
  it "should get_attributes for an object" do
    get_attributes(User.new).should == ["before_add_for_bookmarks", "after_add_for_bookmarks", "before_remove_for_bookmarks", "after_remove_for_bookmarks", "before_add_for_searches", "after_add_for_searches", "before_remove_for_searches", "after_remove_for_searches", "password_confirmation", "user_attributes", "remember_me", "extend_remember_period", "password", "documents_to_bookmark", "bookmarks", "bookmark_ids", "searches", "search_ids", "id", "email", "encrypted_password", "reset_password_token", "reset_password_sent_at", "remember_created_at", "sign_in_count", "current_sign_in_at", "last_sign_in_at", "current_sign_in_ip", "last_sign_in_ip", "created_at", "updated_at", "store_full_sti_class", "_accessible_attributes", "_protected_attributes", "_active_authorizer", "_mass_assignment_sanitizer", "partial_updates", "serialized_attributes", "record_timestamps", "_validation_callbacks", "_initialize_callbacks", "_find_callbacks", "_touch_callbacks", "_save_callbacks", "_create_callbacks", "_update_callbacks", "_destroy_callbacks", "include_root_in_json", "reflections", "_commit_callbacks", "_rollback_callbacks", "attributes"] 
  end
  
  it "should set the correct text for empty objects" do
    hydrus_object_setting_value(nil).should == '<span class="unspecified">not specified</span>'
    hydrus_object_setting_value('').should == '<span class="unspecified">not specified</span>'
    hydrus_object_setting_value('cool dude').should == 'cool dude'
  end

  it "should be able to exercise both branches of hydrus_format_date()" do
    hydrus_format_date('').should == ''
    hydrus_format_date('1999-03-31').should == 'Mar 31, 1999'
  end

  it "should return a correct license image" do
    license_image('cc_by').should == "<img alt=\"Cc_by\" src=\"/images/licenses/cc_by.png\" />"
    license_image('pddl').should be nil
  end
  
  it "should return a correct license link" do
    license_link('cc_by').should == "<a href=\"http://creativecommons.org/licenses/\">{&quot;Creative Commons Licenses&quot;=&gt;[[&quot;CC BY Attribution&quot;, &quot;cc-by&quot;], [&quot;CC BY-SA Attribution Share Alike&quot;, &quot;cc-by-sa&quot;], [&quot;CC BY-ND Attribution-NoDerivs&quot;, &quot;cc-by-nd&quot;], [&quot;CC BY-NC Attribution-NonCommercial&quot;, &quot;cc-by-nc&quot;], [&quot;CC BY-NC-SA Attribution-NonCommercial-ShareAlike&quot;, &quot;cc-by-nc-sa&quot;], [&quot;CC BY-NC-ND Attribution-NonCommercial-NoDerivs&quot;, &quot;cc-by-nc-nd&quot;]], &quot;Open Data Commons Licenses&quot;=&gt;[[&quot;PDDL Public Domain Dedication and License&quot;, &quot;pddl&quot;], [&quot;ODC-By Attribution License&quot;, &quot;odc-by&quot;], [&quot;ODC-ODbl Open Database License&quot;, &quot;odc-odbl&quot;]]}</a>"
    license_link('pddl').should == "<a href=\"http://opendatacommons.org/licenses/\">PDDL Public Domain Dedication and License</a>"
    license_link('junkola').should == "junkola"
  end
  
  it "should strip text values including nil" do
    hydrus_strip(' text  ').should == 'text'
    hydrus_strip('text').should == 'text'
    hydrus_strip(nil).should == ''    
  end
  
  it "should return item title links, showing special text when blank" do
    hi=Hydrus::Item.new
    hi2=Hydrus::Item.find('druid:oo000oo0001')
    item_title_link(hi).should == '<a href="/items">new item</a>'
    item_title_link(hi2).should == '<a href="/items/druid:oo000oo0001">How Couples Meet and Stay Together</a>'
  end
  
  it "should show select status checkbox icon" do
    select_status_checkbox_icon(true).should == '<i class="icon-check"></i>'
    select_status_checkbox_icon(false).should == '<i class="icon-minus"></i>'
  end
  
  it "seen_beta_dialog? should be shown only once" do
    # Initially, we haven't seen the dialog.
    session[:seen_beta_dialog] = false
    seen_beta_dialog?.should == false
    # After seeing dialog, the flag is true.
    session[:seen_beta_dialog].should == true
    seen_beta_dialog?.should == true
  end

  it "formatted_datetime() should return formatted date strings" do
    tests = [
      ['2012-08-10T06:11:57-0700', :date,     '10-Aug-2012'],
      ['2012-08-10T06:11:57-0700', :time,     '06:11 am'],
      ['2012-08-10T06:11:57-0700', :datetime, '10-Aug-2012 06:11 am'],
      ['blah'                    , nil,        nil],
      [nil                       , nil,        nil],
    ]
    tests.each do |input, fmt, exp|
      formatted_datetime(input, fmt).should == exp
    end
  end
  
  it "should set the terms of deposit path" do
    terms_of_deposit_path('druid:oo000oo0001').should == '/items/terms_of_deposit?pid=druid%3Aoo000oo0001'
  end

  it "should set the terms of deposit agree path" do
    terms_of_deposit_agree_path('druid:oo000oo0001').should == '/items/agree_to_terms_of_deposit?pid=druid%3Aoo000oo0001'
  end
  
  it "should show edit item text" do
    hi=Hydrus::Item.new
    edit_item_text(hi).should == 'Edit Draft'
  end
    
  describe "render helpers" do
    it "should return a string that corresponds to the view path for that model" do
      view_path_from_model(Hydrus::Collection.new(:pid=>"1234")).should == "hydrus_collections"
      view_path_from_model(Hydrus::Item.new(:pid=>"1234")).should       == "hydrus_items"
    end
  end

end

