require 'spec_helper'

class MockController
  include Hydrus::AccessControlsEnforcement

  attr_accessor(:flash, :params, :root_path)

  def initialize(ps = {})
    @flash     = {}
    @params    = ps
    @root_path = '/users/signin'
  end

end

describe Hydrus::AccessControlsEnforcement do

  before(:each) do
    @mc     = MockController.new
    @dru    = 'druid:oo000oo9999'
    @exp_rp = @mc.root_path
    @exp_pp = 'polymorphic/path'
  end

  describe "enforce_show_permissions" do

    before(:each) do
      @mc = MockController.new(:id => @dru)
      @mc.stub('current_user').and_return(nil)
      @mc.stub('session').and_return({})
      @mc.stub('request').and_return(OpenStruct.new(:full_path=>'some/fake/path'))
      @mc.stub('new_signin_path').and_return('/users/signin')
    end
    
    it "should do nothing if the user can read the object" do
      @mc.stub('can?').and_return(true)
      @mc.should_not_receive(:redirect_to)
      @mc.enforce_show_permissions
      @mc.flash.should == {}
    end

    it "should redirect to root path if user cannot read the object" do
      @mc.stub('can?').and_return(false)
      @mc.should_receive(:redirect_to).with(@exp_rp)
      @mc.enforce_show_permissions
      f = @mc.flash
      f.should include(:error)
      f[:error].should =~ /privileges.+view/
    end

  end

  describe "enforce_edit_permissions" do

    before(:each) do
      @mc = MockController.new(:id => @dru)
      @mc.stub('session').and_return({})
      @mc.stub('request').and_return(OpenStruct.new(:full_path=>'some/fake/path'))
      @mc.stub('new_signin_path').and_return('/users/signin')
    end

    it "should do nothing if the user can edit the object" do
      @mc.stub('can?').and_return(true)
      @mc.stub('current_user').and_return(nil)      
      @mc.should_not_receive(:redirect_to)
      @mc.enforce_edit_permissions
      @mc.flash.should == {}
    end

    it "should redirect to view page if user cannot edit the object" do
      @mc.stub('can?').and_return(false)
      @mc.stub('current_user').and_return(OpenStruct.new)
      @mc.stub(:polymorphic_path).and_return(@exp_pp)
      @mc.should_receive(:redirect_to).with(@exp_pp)
      mock_coll = double('mock_coll', :hydrus_class_to_s => 'Collection')
      ActiveFedora::Base.stub(:find).and_return(mock_coll)
      @mc.enforce_edit_permissions
      f = @mc.flash
      f.should include(:error)
      f[:error].should =~ /privileges.+edit/
    end

  end

  describe "enforce_create_permissions: create items in collections" do
    
    before(:each) do
      @mc = MockController.new(:id => @dru)
      @mc.stub('current_user').and_return(OpenStruct.new)      
      @mc.stub('session').and_return({})
      @mc.stub('request').and_return(OpenStruct.new(:full_path=>'some/fake/path'))
      @mc.stub('new_signin_path').and_return('/users/signin')
    end
    
    it "should do nothing if the user can do it" do
      @mc.stub('can?').and_return(true)
      @mc.should_not_receive(:redirect_to)
      @mc.enforce_create_permissions
      @mc.flash.should == {}
    end

    it "should redirect to collection view if user cannot do it" do
      @mc.stub('can?').and_return(false)
      @mc.stub('params').and_return({:collection=>'druid:oo000oo0003'})      
      @mc.stub(:polymorphic_path).and_return(@exp_pp)
      @mc.should_receive(:redirect_to).with(@exp_pp)
      Hydrus::Collection.stub(:find)
      @mc.enforce_create_permissions
      f = @mc.flash
      f.should include(:error)
      f[:error].should =~ /privileges.+create items in/
    end

  end

  describe "enforce_create_permissions: create collections" do

    before(:each) do
      @mc = MockController.new()
      @mc.stub('current_user').and_return(nil)
      @mc.stub('session').and_return({})
      @mc.stub('request').and_return(OpenStruct.new(:full_path=>'some/fake/path'))
      @mc.stub('new_signin_path').and_return('/users/signin')
    end

    it "should do nothing if the user can do it" do
      @mc.stub('can?').and_return(true)
      @mc.should_not_receive(:redirect_to)
      @mc.enforce_create_permissions
      @mc.flash.should == {}
    end

    it "should redirect to home page if user cannot do it" do
      @mc.stub('can?').and_return(false)
      @mc.should_receive(:redirect_to).with(@exp_rp)
      @mc.enforce_create_permissions
      f = @mc.flash
      f.should include(:error)
      f[:error].should =~ /privileges.+create new collections/
    end

  end

  describe "apply_gated_discovery modifies the SOLR :fq parameters hash" do

    before(:each) do
      hmc = [
        '"info:fedora/afmodel:Hydrus_Collection"',
        '"info:fedora/afmodel:Hydrus_Item"',
      ].join(' OR ')
      @has_model_clause = %Q<has_model_s:(#{hmc})>
    end

    it "hash should include expected clauses for the normal use case" do
      @mc = MockController.new()
      @mc.stub(:current_user).and_return('userFoo')
      apo_pids = %w(aaa bbb)
      Hydrus::Collection.stub(:apos_involving_user).and_return(apo_pids)
      parts = {
        :igb => %Q<is_governed_by_s:("info:fedora/aaa" OR "info:fedora/bbb")>,
        :rmd => %Q<roleMetadata_role_person_identifier_t:"userFoo">,
        :hm  => @has_model_clause,
      }
      exp = {
        :a  => 'blah',
        :fq => [
          "#{parts[:igb]} OR #{parts[:rmd]}",
          "#{parts[:hm]}",
        ],
      }
      solr_params = {:a => 'blah'}
      @mc.apply_gated_discovery(solr_params, {})
      solr_params.should == exp
    end
    
    it "hash should include a non-existent model if user is not logged in" do
      @mc = MockController.new()
      @mc.stub(:current_user).and_return(nil)
      parts = {
        :hm1 => @has_model_clause,
        :hm2 => %Q<has_model_s:("info:fedora/afmodel:____USER_IS_NOT_LOGGED_IN____")>,
      }
      exp = { :fq => [ parts[:hm1], parts[:hm2] ] }
      solr_params = {}
      @mc.apply_gated_discovery(solr_params, {})
      solr_params.should == exp
    end
    
  end

end
