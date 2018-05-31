# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/sul_chrome/_main_container.html.erb' do
  before do
    allow(Settings.hydrus).to receive(:show_test_banner?).and_return(banner)
    render
  end

  context 'when test banner is on' do
    let(:banner) { true }

    it 'shows the banner' do
      expect(rendered).to have_selector 'img[src^="/assets/test-version-ribbon"]'
    end
  end

  context 'when test banner is off' do
    let(:banner) { false }

    it "doesn't show the banner" do
      expect(rendered).not_to have_selector 'img[src^="/assets/test-version-ribbon"]'
    end
  end
end
