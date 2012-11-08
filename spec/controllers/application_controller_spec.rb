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

  it "can exercise errors_for_display()" do
    obj = double('mock-object')
    msgs = {
      :files => ['foo bar', 'fubb'],
      :title => ['blah blah'],
    }
    exp = 'Files foo bar, fubb.<br/>Title blah blah.'
    obj.stub_chain(:errors, :messages).and_return(msgs)
    controller.send(:errors_for_display, obj).should == exp
  end

  it "can exercise try_to_save()" do
    # Successful save().
    flash[:notice].should == nil
    obj = double('obj', :save => true)
    msg = 'foo message'
    controller.send(:try_to_save, obj, msg).should == true
    flash[:notice].should == msg

    # Failed save().
    flash[:error].should == nil
    obj = double('obj', :save => false)
    msg = 'foo error message'
    controller.stub(:errors_for_display).and_return(msg)
    controller.send(:try_to_save, obj, 'blah').should == false
    flash[:error].should == msg
  end
  
end
