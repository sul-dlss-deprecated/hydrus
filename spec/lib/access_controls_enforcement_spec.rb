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
  end

  describe 'enforce_show_permissions' do
    before(:each) do
      @mc = MockController.new(id: @dru)
      allow(@mc).to receive('current_user').and_return(nil)
      allow(@mc).to receive('session').and_return({})
      allow(@mc).to receive('request').and_return(OpenStruct.new(full_path: 'some/fake/path'))
      allow(@mc).to receive('new_user_session_path').and_return('/users/signin')
    end

    it 'should do nothing if the user can read the object' do
      allow(@mc).to receive('can?').and_return(true)
      expect(@mc).not_to receive(:redirect_to)
      @mc.enforce_show_permissions
      expect(@mc.flash).to eq({})
    end

    it 'should redirect to root path if user cannot read the object' do
      allow(@mc).to receive('current_user').and_return('')
      allow(@mc).to receive('can?').and_return(false)
      allow(@mc).to receive(:root_url).and_return('/')
      expect(@mc).to receive(:redirect_to).with(@exp_rp)
      @mc.enforce_show_permissions
      f = @mc.flash
      expect(f).to include(:error)
      expect(f[:error]).to match(/privileges.+view/)
    end
    it 'should redirect with a more friendly message if user isnt logged in' do
      allow(@mc).to receive('can?').and_return(false)
      allow(@mc).to receive(:root_url).and_return('/')
      expect(@mc).to receive(:redirect_to).with(@exp_rp)
      @mc.enforce_show_permissions
      f = @mc.flash
      expect(f).to include(:error)
      expect(f[:error]).to eq('Please sign in below and you will be directed to the requested item: \'druid:oo000oo9999\'.')
    end
  end

  describe 'enforce_edit_permissions' do
    before(:each) do
      @mc = MockController.new(id: @dru)
      allow(@mc).to receive('session').and_return({})
      allow(@mc).to receive('request').and_return(OpenStruct.new(full_path: 'some/fake/path'))
      allow(@mc).to receive('new_user_session_path').and_return('/users/signin')
    end

    it 'should do nothing if the user can edit the object' do
      allow(@mc).to receive('can?').and_return(true)
      allow(@mc).to receive('current_user').and_return(nil)
      expect(@mc).not_to receive(:redirect_to)
      @mc.enforce_edit_permissions
      expect(@mc.flash).to eq({})
    end

    it 'should redirect to view page if user cannot edit the object' do
      allow(@mc).to receive('can?').and_return(false)
      allow(@mc).to receive(:root_url).and_return('/')
      allow(@mc).to receive('current_user').and_return(OpenStruct.new)
      allow(@mc).to receive(:root_path).and_return(@exp_rp)
      expect(@mc).to receive(:redirect_to).with(@exp_rp)
      @mc.enforce_edit_permissions
      f = @mc.flash
      expect(f).to include(:error)
      expect(f[:error]).to match(/privileges.+edit/)
    end
  end

  describe 'enforce_create_permissions: create items in collections' do
    before(:each) do
      @mc = MockController.new(id: @dru)
      allow(@mc).to receive('current_user').and_return(OpenStruct.new)
      allow(@mc).to receive('session').and_return({})
      allow(@mc).to receive('request').and_return(OpenStruct.new(full_path: 'some/fake/path'))
      allow(@mc).to receive('new_user_session_path').and_return('/users/signin')
    end

    it 'should do nothing if the user can do it' do
      allow(@mc).to receive('can?').and_return(true)
      expect(@mc).not_to receive(:redirect_to)
      @mc.enforce_create_permissions
      expect(@mc.flash).to eq({})
    end

    it 'should redirect to home page if user cannot do it' do
      allow(@mc).to receive('can?').and_return(false)
      allow(@mc).to receive(:root_url).and_return('/')
      allow(@mc).to receive('params').and_return({ collection: 'druid:oo000oo0003' })
      allow(@mc).to receive(:root_path).and_return(@exp_rp)
      expect(@mc).to receive(:redirect_to).with(@exp_rp)
      @mc.enforce_create_permissions
      f = @mc.flash
      expect(f).to include(:error)
      expect(f[:error]).to match(/privileges.+create items in/)
    end
  end

  describe 'enforce_create_permissions: create collections' do
    before(:each) do
      @mc = MockController.new()
      allow(@mc).to receive('current_user').and_return(nil)
      allow(@mc).to receive('session').and_return({})
      allow(@mc).to receive('request').and_return(OpenStruct.new(full_path: 'some/fake/path'))
      allow(@mc).to receive('new_user_session_path').and_return('/users/signin')
    end

    it 'should do nothing if the user can do it' do
      allow(@mc).to receive('can?').and_return(true)
      expect(@mc).not_to receive(:redirect_to)
      @mc.enforce_create_permissions
      expect(@mc.flash).to eq({})
    end

    it 'should redirect to home page if user cannot do it' do
      allow(@mc).to receive('can?').and_return(false)
      allow(@mc).to receive(:root_url).and_return('/')
      expect(@mc).to receive(:redirect_to).with(@exp_rp)
      @mc.enforce_create_permissions
      f = @mc.flash
      expect(f).to include(:error)
      expect(f[:error]).to match(/privileges.+create new collections/)
    end
  end

  describe 'apply_gated_discovery modifies the SOLR :fq parameters hash' do
    before(:each) do
      hmc = [
        '"info:fedora/afmodel:Hydrus_Collection"',
        '"info:fedora/afmodel:Hydrus_Item"',
      ].join(' OR ')
      @has_model_clause = %Q<has_model_ssim:(#{hmc})>
    end

    it 'hash should include expected clauses for the normal use case' do
      @mc = MockController.new()
      allow(@mc).to receive(:current_user).and_return('userFoo')
      apo_pids = %w(aaa bbb)
      allow(Hydrus::Collection).to receive(:apos_involving_user).and_return(apo_pids)
      parts = {
        igb: %Q<is_governed_by_ssim:("info:fedora/aaa" OR "info:fedora/bbb")>,
        rmd: %Q<role_person_identifier_sim:"userFoo">,
        hm: @has_model_clause,
      }
      exp = {
        a: 'blah',
        fq: [
          "#{parts[:igb]} OR #{parts[:rmd]}",
          "#{parts[:hm]}",
        ],
      }
      solr_params = { a: 'blah' }
      @mc.apply_gated_discovery(solr_params, {})
      expect(solr_params).to eq(exp)
    end

    it 'hash should include a non-existent model if user is not logged in' do
      @mc = MockController.new()
      allow(@mc).to receive(:current_user).and_return(nil)
      parts = {
        hm1: @has_model_clause,
        hm2: %Q<has_model_ssim:("info:fedora/afmodel:____USER_IS_NOT_LOGGED_IN____")>,
      }
      exp = { fq: [parts[:hm1], parts[:hm2]] }
      solr_params = {}
      @mc.apply_gated_discovery(solr_params, {})
      expect(solr_params).to eq(exp)
    end
  end
end
