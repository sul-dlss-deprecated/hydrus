require 'spec_helper'

describe ApplicationController do

  it "should have the correct layout name" do
    controller.layout_name.should == 'sul_chrome/application'
  end
  
  it "is_production? should behave as expected" do
    tests = [
      # expected  Rails.production?  request.env['HTTP_HOST']
      [true,      true,              %w()],
      [false,     false,             %w()],
      [false,     true,              nil],
      [false,     true,              %w(foo -test)],
      [false,     true,              %w(foo -dev)],
      [false,     true,              %w(foo localhost)],
    ]
    tests.each do |exp, prod_val, hh_val|
      mock_rails_env   = double('env', 'production?'.to_sym => prod_val)
      mock_request_env = { 'HTTP_HOST' => hh_val }
      Rails.stub(:env).and_return(mock_rails_env)
      request.stub(:env).and_return(mock_request_env)
      controller.is_production?.should == exp
    end
  end
  
end
