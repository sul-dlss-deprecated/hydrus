# frozen_string_literal: true
require 'spec_helper'

describe 'Mock Authenticated User' do
  # binding.pry
  # sanity check
  it 'mock_auth_user non-null' do
    u = mock_authed_user
    expect(u).not_to be_nil
  end
end
