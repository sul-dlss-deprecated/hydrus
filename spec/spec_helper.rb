# for test coverage
ruby_engine = defined?(RUBY_ENGINE) ? RUBY_ENGINE : "ruby"

if ENV['COVERAGE'] == "true" and ruby_engine != "jruby"
  require 'simplecov'
  require 'simplecov-rcov'

  class SimpleCov::Formatter::MergedFormatter
    def format(result)
       SimpleCov::Formatter::HTMLFormatter.new.format(result)
       SimpleCov::Formatter::RcovFormatter.new.format(result)
    end
  end
  SimpleCov.formatter = SimpleCov::Formatter::MergedFormatter
  SimpleCov.start do
    # group coverage data
    add_group "Controllers", "app/controllers"
    add_group "Helpers", "app/helpers"
    add_group "Mailers", "app/mailers"
    add_group "Models", "app/models"
    # exclude from coverage
    add_filter "config/"
    add_filter "features/"
    add_filter "spec/"
  end
end

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'capybara/rspec'
require 'tempfile'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|

  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/test/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Restore prior state of Fedora repository.
  config.around(:each) do |example|
    ActiveFedora::Base.connection_for_pid(0).transaction do |t|
      example.call
      # TODO: simplify if rollback_fixtures() is incorporated into Rubydora.
      if ENV['USE_OLD_ROLLBACK']
        t.rollback
      else
        t.rollback_fixtures(FIXTURE_FOXML)
      end
    end
  end

end

Dor::Config.configure.suri.mint_ids = false

FIXTURE_FOXML = Hydrus.all_fixture_foxml()

# TODO: incorporate this into Rubydora.
# Relative to rollback() it Rubydora v0.5.0, it reduced
# test suite runtime from 32 min down to about 8 min.
# Not sure what the two run_hook() calls do or whether they are needed;
# just copied the approach used in Rubydora's rollback().
class Rubydora::Transaction

    # Roll-back transactions by restoring the repository to its
    # original state, based on fixtures that are passed in as a
    # hash, with PIDs and keys and foxml as values.
    def rollback_fixtures(fixtures)
      # Two sets of PIDs:
      #   - everything that was modified
      #   - fixtures that were modified
      aps = Set.new(all_pids)
      fps = Set.new(fixtures.keys) & aps
      # Rollback.
      # Just swallow any exceptions.
      without_transactions do
        # First, purge everything that was modified.
        aps.each do |p|
          begin
            repository.purge_object(:pid => p)
            run_hook(:after_rollback, :pid => p, :method => :ingest)
          rescue
          end
        end
        # Then restore the fixtures to their original state.
        fixtures.each do |p, foxml|
          next unless fps.include?(p)
          begin
            repository.ingest(:pid => p, :file => foxml)
            run_hook(:after_rollback, :pid => p, :method => :purge_object)
          rescue
          end
        end
      end
      # Wrap up.
      repository.transactions_log.clear
      return true
    end

    # Returns the pids of all objects modified in any way during the transaction.
    def all_pids
      repository.transactions_log.map { |entry| entry.last[:pid] }.uniq
    end

end

# Create a Nokogiri document from an XML source, with some whitespace configuration.
def noko_doc(x)
  Nokogiri.XML(x) { |conf| conf.default_xml.noblanks }
end

def mock_user
  mock_user =  mock("user")
  mock_user.stub!(:email)
  mock_user.stub!(:sunetid)
  mock_user.stub!(:persisted?).and_return(false)
  mock_user.stub!(:new_record?).and_return(true)
  mock_user.stub!(:is_being_superuser?).and_return(false)
  return mock_user
end

def mock_authed_user(u = 'archivist1')
  mock_user =  mock("user")
  mock_user.stub!(:to_s).and_return(u)
  mock_user.stub!(:sunetid).and_return(u)
  mock_user.stub!(:email).and_return("#{u}@example.com")
  mock_user.stub!(:persisted?).and_return(true)
  mock_user.stub!(:new_record?).and_return(false)
  mock_user.stub!(:is_being_superuser?).and_return(false)
  return mock_user
end

def login_pw
  'beatcal'
end

def login_as(email, password = nil)
  password ||= login_pw
  email += '@example.com' unless email.include?('@')
  logout
  visit new_user_session_path
  fill_in "Email", :with => email
  fill_in "Password", :with => password
  click_button "Sign in"
end

def logout
  visit destroy_user_session_path
end

# Takes a hash and returns a corresponding Struct.
def hash2struct(h)
  return Struct.new(*h.keys).new(*h.values)
end

def should_visit_view_page(obj)
  visit polymorphic_path(obj)
  current_path.should == polymorphic_path(obj)
end

def should_visit_edit_page(obj)
  visit edit_polymorphic_path(obj)
  current_path.should == edit_polymorphic_path(obj)
end

# Takes a collection.
# Visits url to create new item in that collection.
# Extracts the new item's druid from the path and returns it.
def should_visit_new_item_page(coll)
  rgx = Regexp.new('/items/(druid:\w{11})/edit')
  visit new_hydrus_item_path(:collection => coll)
  current_path.should =~ rgx
  druid = rgx.match(current_path)[1]
  return druid
end

def confirm_rights_metadata_in_apo(obj)
  obj.apo.defaultObjectRights.ng_xml.should be_equivalent_to obj.rightsMetadata.ng_xml # collection rights metadata should be equal to apo default object rights
end

def check_emb_vis_lic(obj, opts)
  # This method takes an Item or Collection and checks various values
  # in its embargoMetadata and rightsMetadata. The expectations are passed in
  # as a hash of options.
  #
  # An object's embargo status affects both the embargoMetadata
  # and rightsMetadata, as summarized here:
  #
  # is_embargoed = true
  #   embargoMetadata
  #     releaseAccess read node should = world|stanford
  #     status = embargoed
  #     releaseDate = DATETIME
  #   rightsMetadata
  #     read access = NONE
  #     embargoReleaseDate = DATETIME
  #
  # is_embargoed = false
  #   embargoMetadata
  #     datastream should be empty
  #   rightsMetadata
  #     read access should = world|stanford
  #     should be no embargoReleaseDate node

  # Some convenience variables.
  di     = '//access[@type="discover"]/machine'
  rd     = '//access[@type="read"]/machine'
  rm     = obj.rightsMetadata
  em     = obj.embargoMetadata
  is_emb = (obj.class == Hydrus::Item and obj.is_embargoed)

  # Consistency between is_embargoed() and testing expectations.
  opts[:embargo_date].blank?.should == not(is_emb)

  # All objects should be world discoverable.
  obj.rightsMetadata.ng_xml.xpath("#{di}/world").size.should == 1
  obj.embargoMetadata.ng_xml.xpath("#{di}/world").size.should == 1 if is_emb

  # Some checks based on embargo status.
  if is_emb
    # embargoMetadata
    em.ng_xml.at_xpath('//status').content.should == 'embargoed'
    em.ng_xml.at_xpath('//releaseDate').content.should == opts[:embargo_date]
    # rightsMetadata
    rm.has_world_read_node.should == false
    rm.group_read_nodes.size.should == 0
    rm.ng_xml.at_xpath("#{rd}/embargoReleaseDate").content.should == opts[:embargo_date]
  else
    # embargoMetadata: should be empty
    em.ng_xml.content.should == ''
    # rightsMetadata: should not have an embargoReleaseDate.
    rm.ng_xml.xpath("#{rd}/embargoReleaseDate").size.should == 0
  end

  # Check visibility: (world|stanford) stored in either embargoMetadata or rightsMetadata.
  datastream = (is_emb ? em : rm)
  g = datastream.ng_xml.xpath("#{rd}/group")
  w = datastream.ng_xml.xpath("#{rd}/world")
  if opts[:visibility] == "stanford"
    g.size.should == 1
    g.first.content.should == 'stanford'
    w.size.should == 0
  else # "world"
    g.size.should == 0
    w.size.should == 1
  end

  # Check the license in rightsMetadata.
  u = obj.rightsMetadata.ng_xml.at_xpath('//use/machine')
  u.content.should == opts[:license_code]
end

# Some integration tests requires the minting of a valid druid in
# order to pass validations. This method can be used to set the mint_ids
# configuration to true, and then latter restore the previous value.
def config_mint_ids(prev = nil)
  suri = Dor::Config.configure.suri
  if prev.nil?
    prev = suri.mint_ids
    suri.mint_ids = true
  else
    suri.mint_ids = prev
  end
  return prev
end

# Creates a new collection through the UI.
# User can pass in options to control how the form is filled out.
# Returns the new collection.
def create_new_collection(opts = {})
  # Setup options.
  default_opts = {
    :user                    => 'archivist1',
    :title                   => 'title_foo',
    :abstract                => 'abstract_foo',
    :contact                 => 'foo@bar.com',
    :requires_human_approval => 'yes',
    :viewers                 => '',
  }
  opts = hash2struct(default_opts.merge opts)
  # Login and create new collection.
  login_as(opts.user)
  visit(new_hydrus_collection_path)
  # Extract the druid from the URL.
  r = Regexp.new('/collections/(druid:\w{11})/edit')
  m = r.match(current_path)
  m.should_not(be_nil)
  druid = m[1]
  # Fill in required fields.
  hc    = 'hydrus_collection'
  rmdiv = find('div#role-management')
  dk    = 'hydrus_collection_apo_person_roles'
  fill_in "#{hc}_title",    :with => opts.title
  fill_in "#{hc}_abstract", :with => opts.abstract
  fill_in "#{hc}_contact",  :with => opts.contact
  fill_in "#{hc}_apo_person_roles[hydrus-collection-viewer]", :with => opts.viewers
  choose  "#{hc}_requires_human_approval_" + opts.requires_human_approval
  # Save.
  click_button "Save"
  current_path.should == "/collections/#{druid}"
  find('div.alert').should have_content("Your changes have been saved")
  # Get the collection from Fedora and return it.
  return Hydrus::Collection.find(druid)
end

# Creates a new item through the UI.
# User can pass in options to control how the form is filled out.
# Returns the new item.
def create_new_item(opts = {})
  # Setup options.
  default_opts = {
    :collection_pid          => 'druid:oo000oo0003',
    :user                    => mock_authed_user,
    :title                   => 'title_foo',
    :abstract                => 'abstract_foo',
    :person                  => 'foo_person',
    :contact                 => 'foo@bar.com',
    :keywords                => 'topicA,topicB',
    :requires_human_approval => 'yes',
  }
  opts = hash2struct(default_opts.merge opts)
  # Set the Collection's require_human_approval value.
  hc = Hydrus::Collection.find(opts.collection_pid)
  hc.requires_human_approval = opts.requires_human_approval
  hc.save
  # Login and create new item.
  login_as(opts.user.to_s)
  visit new_hydrus_item_path(:collection => hc.pid)
  # Extract the druid from the URL.
  r = Regexp.new('/items/(druid:\w{11})/edit')
  m = r.match(current_path)
  m.should_not(be_nil)
  druid = m[1]
  # Fill in the required fields.
  click_button('Add Person')
  fill_in "hydrus_item_person_0", :with => opts.person
  fill_in "Title of item",        :with => opts.title
  fill_in "hydrus_item_abstract", :with => opts.abstract
  fill_in "hydrus_item_contact",  :with => opts.contact
  fill_in "hydrus_item_keywords", :with => opts.keywords
  check "release_settings"
  # Add a file.
  f      = Hydrus::ObjectFile.new
  f.pid  = druid
  f.file = Tempfile.new('mock_HydrusObjectFile_')
  f.save
  # Save.
  click_button "Save"
  current_path.should == "/items/#{druid}"
  find('div.alert').should have_content("Your changes have been saved")
  # Agree to terms of deposit (hard to do via the UI).
  hi = Hydrus::Item.find(druid)
  hi.accept_terms_of_deposit(opts.user)
  hi.save
  # Get the item from Fedora and return it.
  should_visit_view_page(hi)
  return Hydrus::Item.find(druid)
end

# Takes the file_url of an Item's uploaded file.
# Helper method to restore a file to the uploads directory
# after it was deleted in a integration test.
def restore_upload_file(file_url)
  parts = file_url.split /\//
  parts[0] = 'public'
  dst = File.join(*parts)
  src = File.join('spec/fixtures/files', parts[-3], parts[-1])
  FileUtils.cp(src, dst)
end
