require 'spec_helper'

describe User, type: :model do
  before(:each) do
    @id    = 'somebody'
    @email = "#{@id}@example.com"
    @u     = User.create(email: @email)
  end

  it 'to_s() should return the user ID portion of the email' do
    expect(@u.to_s).to eq(@id)
  end
end
