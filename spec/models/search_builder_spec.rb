require 'spec_helper'

RSpec.describe SearchBuilder do
  subject(:builder) { described_class.new(nil, nil) }

  describe 'apply_gated_discovery' do
    let(:has_model_clause) do
      hmc = [
        '"info:fedora/afmodel:Hydrus_Collection"',
        '"info:fedora/afmodel:Hydrus_Item"',
      ].join(' OR ')
      %<has_model_ssim:(#{hmc})>
    end

    it 'hash should include expected clauses for the normal use case' do
      allow(builder).to receive(:current_user).and_return('userFoo')
      apo_pids = %w(aaa bbb)
      allow(Hydrus::Collection).to receive(:apos_involving_user).and_return(apo_pids)
      parts = {
        igb: %<is_governed_by_ssim:("info:fedora/aaa" OR "info:fedora/bbb")>,
        rmd: %<role_person_identifier_sim:"userFoo">,
        hm: has_model_clause,
      }
      exp = {
        a: 'blah',
        fq: [
          "#{parts[:igb]} OR #{parts[:rmd]}",
          (parts[:hm]).to_s,
        ],
      }
      solr_params = { a: 'blah' }
      builder.send(:apply_gated_discovery, solr_params)
      expect(solr_params).to eq(exp)
    end

    it 'hash should include a non-existent model if user is not logged in' do
      allow(builder).to receive(:current_user).and_return(nil)
      parts = {
        hm1: has_model_clause,
        hm2: %<has_model_ssim:("info:fedora/afmodel:____USER_IS_NOT_LOGGED_IN____")>,
      }
      exp = { fq: [parts[:hm1], parts[:hm2]] }
      solr_params = {}
      builder.send(:apply_gated_discovery, solr_params)
      expect(solr_params).to eq(exp)
    end
  end
end
