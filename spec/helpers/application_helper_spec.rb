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
    hydrus_is_empty?(Hydrus::Contributor.new).should be true
    hydrus_is_empty?(['',['stuff']]).should be false
    hydrus_is_empty?(['stuff']).should be false
    hydrus_is_empty?('stuff').should be false
    hydrus_is_empty?(Hydrus::Contributor.new(:name=>'peter',:role=>'el jefe')).should be false
  end

  it "should show the item edit tab appropriately" do
    [false, true].each do |exp|
      item = mock(Hydrus::Item, :is_published => !exp)
      show_item_edit(item).should == exp
    end
  end

  it "should render the correct contextual layout" do
    controller=mock(HydrusCollectionsController)
    render_contextual_layout.should == "<ul class=\"breadcrumb\">\n  <li><a href=\"/\">Home</a></li>\n</ul>\n\n\n<div class=\"row\">\n  <div class=\"span9\" id=\"main\"></div>\n  <div class=\"span3\" id=\"sidebar\"></div>\n</div>\n"
  end

  it "should get_attributes for an object" do
    get_attributes(User.new).should == [
      "before_add_for_bookmarks",
      "after_add_for_bookmarks",
      "before_remove_for_bookmarks",
      "after_remove_for_bookmarks",
      "before_add_for_searches",
      "after_add_for_searches",
      "before_remove_for_searches",
      "after_remove_for_searches",
      "password_confirmation",
      "user_attributes",
      "remember_me",
      "extend_remember_period",
      "password",
      "documents_to_bookmark",
      "bookmarks",
      "bookmark_ids",
      "searches",
      "search_ids",
      "id",
      "email",
      "encrypted_password",
      "reset_password_token",
      "reset_password_sent_at",
      "remember_created_at",
      "sign_in_count",
      "current_sign_in_at",
      "last_sign_in_at",
      "current_sign_in_ip",
      "last_sign_in_ip",
      "created_at",
      "updated_at",
      "store_full_sti_class",
      "_accessible_attributes",
      "_protected_attributes",
      "_active_authorizer",
      "_mass_assignment_sanitizer",
      "partial_updates",
      "serialized_attributes",
      "record_timestamps",
      "_validation_callbacks",
      "_initialize_callbacks",
      "_find_callbacks",
      "_touch_callbacks",
      "_save_callbacks",
      "_create_callbacks",
      "_update_callbacks",
      "_destroy_callbacks",
      "include_root_in_json",
      "reflections",
      "_commit_callbacks",
      "_rollback_callbacks",
      "attributes"]
  end

  it "should set the correct text for empty objects" do
    exp_unsp = '<span class="unspecified">to be entered</span>'
    exp_na   = '<span class="muted">not available yet</span>'
    hydrus_object_setting_value(nil).should == exp_unsp
    hydrus_object_setting_value('').should == exp_unsp
    hydrus_object_setting_value('', :na => true).should == exp_na
    hydrus_object_setting_value('cool dude').should == 'cool dude'
  end

  it "license_image()" do
    license_image('cc-by').should == '<img alt="Cc_by" src="/images/licenses/cc_by.png" />'
    license_image('pddl').should == ''
    license_image('none').should == ''
  end

  it "should return a correct license link" do
    license_link('cc-by').should == '<a href="http://creativecommons.org/licenses/">CC BY Attribution</a>'
    license_link('pddl').should  == '<a href="http://opendatacommons.org/licenses/">PDDL Public Domain Dedication and License</a>'
    license_link('none').should == 'No license'
    license_link('junkola').should == 'Unknown license'
  end

  it "should strip text values including nil" do
    hydrus_strip(' text  ').should == 'text'
    hydrus_strip('text').should == 'text'
    hydrus_strip(nil).should == ''
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

  describe "item title link helpers", :integration=>true do

    it "should return item title links, showing special text when blank" do
      hi=Hydrus::Item.new
      hi2=Hydrus::Item.find('druid:oo000oo0001')
      title_text(hi).should == 'Untitled'
      title_text(hi2).should == 'How Couples Meet and Stay Together'
      title_link(hi).should == '<a href="/items">Untitled</a>'
      title_link(hi2).should == '<a href="/items/druid:oo000oo0001">How Couples Meet and Stay Together</a>'
    end

  end

  it "show_line_breaks()" do
    br = '<br/>'
    txt = [
      'hello',
      "\r\n", "\r\n", "\n",       # Various newline styles.
      '<script>DANGER</script>',  # Injected JavaScript.
      "\r",   "\r",   "\r\n",     # More newlines.
      'world',
    ].join
    exp = [
      'hello',
      br, br, br,
      '&lt;script&gt;DANGER&lt;/script&gt;',  # Safely escaped.
      br, br, br,
      'world',
    ].join
    show_line_breaks(txt).should == exp
  end

end

