require 'spec_helper'

describe ApplicationHelper, :type => :helper do

  include ApplicationHelper

  # fake out some methods to make our tests pass
  def can?(action,item)
    true
  end

  it "should show correct view_item_text" do
    hi=Hydrus::Item.new
    allow(hi).to receive(:is_published).and_return(true)
    expect(helper.view_item_text(hi)).to eq('Published Version')
    allow(hi).to receive(:is_published).and_return(false)
    expect(helper.view_item_text(hi)).to eq('View Draft')
  end

  it "should get the local application name" do
    expect(helper.application_name).to eq("Stanford Digital Repository")
  end

  it "should show the signin link" do
    allow(controller.request).to receive(:fullpath).and_return('/items/oo000oo0001')
    expect(helper.hydrus_signin_link).to have_link 'Sign in', href: "/users/sign_in?referrer=%2Fitems%2Foo000oo0001"
  end

  it "should indicate if an object is empty" do
    expect(hydrus_is_empty?(nil)).to be true
    expect(hydrus_is_empty?('')).to be true
    expect(hydrus_is_empty?(['',''])).to be true
    expect(hydrus_is_empty?(['',['']])).to be true
    expect(hydrus_is_empty?(Hydrus::Contributor.new)).to be true
    expect(hydrus_is_empty?(['',['stuff']])).to be false
    expect(hydrus_is_empty?(['stuff'])).to be false
    expect(hydrus_is_empty?('stuff')).to be false
    expect(hydrus_is_empty?(Hydrus::Contributor.new(:name=>'peter',:role=>'el jefe'))).to be false
  end

  it 'should show the item edit tab if the item is not published' do
    item = double(Hydrus::Item, :is_published => true)
    expect(show_item_edit(item)).to eq(false)
  end

  it 'should not show the item edit tab if the item is published' do
    item = double(Hydrus::Item, :is_published => false)
    expect(show_item_edit(item)).to eq(true)
  end

  it "should render the correct contextual layout" do
    controller=double("HydrusCollectionsController")
    rendered = helper.render_contextual_layout

    expect(rendered).to have_selector 'ul.breadcrumb'
    expect(rendered).to have_link 'Home', '/'
    expect(rendered).to have_selector '.row #main'
    expect(rendered).to have_selector '.row #sidebar'
  end

  it "should set the correct text for empty objects" do
    exp_unsp = '<span class="unspecified">to be entered</span>'
    exp_na   = '<span class="muted">not available yet</span>'
    expect(hydrus_object_setting_value(nil)).to eq(exp_unsp)
    expect(hydrus_object_setting_value('')).to eq(exp_unsp)
    expect(hydrus_object_setting_value('', :na => true)).to eq(exp_na)
    expect(hydrus_object_setting_value('cool dude')).to eq('cool dude')
  end

  it "license_image()" do
    expect(license_image('cc-by')).to have_selector 'img[@src="/images/licenses/cc_by.png"][@alt="Cc by"]'
    expect(license_image('pddl')).to eq('')
    expect(license_image('none')).to eq('')
  end

  it "should return a correct license link" do
    expect(license_link('cc-by')).to eq('<a href="http://creativecommons.org/licenses/">CC BY Attribution</a>')
    expect(license_link('pddl')).to  eq('<a href="http://opendatacommons.org/licenses/">PDDL Public Domain Dedication and License</a>')
    expect(license_link('none')).to eq('No license')
    expect(license_link('junkola')).to eq('Unknown license')
  end

  it "should strip text values including nil" do
    expect(hydrus_strip(' text  ')).to eq('text')
    expect(hydrus_strip('text')).to eq('text')
    expect(hydrus_strip(nil)).to eq('')
  end

  it "should show select status checkbox icon" do
    expect(select_status_checkbox_icon(true)).to eq('<i class="icon-check"></i>')
    expect(select_status_checkbox_icon(false)).to eq('<i class="icon-minus"></i>')
  end

  it "seen_beta_dialog? should be shown only once" do
    # Initially, we haven't seen the dialog.
    session[:seen_beta_dialog] = false
    expect(seen_beta_dialog?).to eq(false)
    # After seeing dialog, the flag is true.
    expect(session[:seen_beta_dialog]).to eq(true)
    expect(seen_beta_dialog?).to eq(true)
  end

  it "should set the terms of deposit path" do
    expect(terms_of_deposit_path('druid:oo000oo0001')).to eq('/items/terms_of_deposit?pid=druid%3Aoo000oo0001')
  end

  it "should set the terms of deposit agree path" do
    expect(helper.terms_of_deposit_agree_path('druid:oo000oo0001')).to eq('/items/agree_to_terms_of_deposit?pid=druid%3Aoo000oo0001')
  end

  it "should show edit item text" do
    hi=Hydrus::Item.new
    expect(helper.edit_item_text(hi)).to eq('Edit Draft')
  end

  describe "render helpers" do
    it "should return a string that corresponds to the view path for that model" do
      expect(helper.view_path_from_model(Hydrus::Collection.new(:pid=>"1234"))).to eq("hydrus_collections")
      expect(helper.view_path_from_model(Hydrus::Item.new(:pid=>"1234"))).to       eq("hydrus_items")
    end
  end

  describe "item title link helpers", :integration=>true do

    it "should return item title links, showing special text when blank" do
      hi=Hydrus::Item.new
      hi2=Hydrus::Item.find('druid:oo000oo0001')
      expect(helper.title_text(hi)).to eq('Untitled')
      expect(helper.title_text(hi2)).to eq('How Couples Meet and Stay Together')
      expect(helper.title_link(hi)).to have_selector 'a[href="/items"][disable_after_click="true"]', text: 'Untitled'
      expect(helper.title_link(hi2)).to have_selector 'a[href="/items/druid:oo000oo0001"][disable_after_click="true"]', text: 'How Couples Meet and Stay Together'
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
    expect(helper.show_line_breaks(txt)).to eq(exp)
  end

end
