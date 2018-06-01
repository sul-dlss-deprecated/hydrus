# frozen_string_literal: true

module Features
  module SessionHelpers
    include Warden::Test::Helpers

    def self.included(base)
      base.before(:each) { Warden.test_mode! }
      base.after(:each) { Warden.test_reset! }
    end

    def sign_in(user = nil, groups: [])
      logout(:user)
      TestShibbolethHeaders.user = user.email
      TestShibbolethHeaders.groups = groups
    end

    def sign_out
      TestShibbolethHeaders.user = nil
      TestShibbolethHeaders.groups = nil
    end
  end
end

RSpec.configure do |config|
  config.include Features::SessionHelpers, type: :feature
  config.include Features::SessionHelpers, type: :request
end
