require 'spec_helper'

describe ApplicationController, :type => :controller do

  it "should have the correct layout name" do
    expect(controller.layout_name).to eq('sul_chrome/application')
  end

  it "is_production? should behave as expected" do
    tests = [
      # expected  Rails.production?  request.env['HTTP_HOST']
      [true,      true,              %w()],
      [false,     false,             %w()],
      [false,     true,              nil],
      [false,     true,              %w(foo -test)],
      [false,     true,              %w(foo -dev)],
      [false,     true,              %w(foo -stage)],
    ]
    tests.each do |exp, prod_val, hh_val|
      mock_rails_env   = double('env', 'production?'.to_sym => prod_val)
      mock_request_env = { 'HTTP_HOST' => hh_val }
      allow(Rails).to receive(:env).and_return(mock_rails_env)
      allow(request).to receive(:env).and_return(mock_request_env)
      expect(controller.is_production?).to eq(exp)
    end
  end

  it "can exercise errors_for_display()" do
    obj = double('mock-object')
    msgs = {
      :files => ['foo bar', 'fubb'],
      :title => ['blah blah'],
    }
    exp = 'Files foo bar, fubb.<br/>Title blah blah.'
    allow(obj).to receive_message_chain(:errors, :messages).and_return(msgs)
    expect(controller.send(:errors_for_display, obj)).to eq(exp)
  end

  it "can exercise try_to_save()" do
    # Successful save().
    expect(flash[:notice]).to eq(nil)
    obj = double('obj', :save => true)
    msg = 'foo message'
    expect(controller.send(:try_to_save, obj, msg)).to eq(true)
    expect(flash[:notice]).to eq(msg)

    # Failed save().
    expect(flash[:error]).to eq(nil)
    obj = double('obj', :save => false)
    msg = 'foo error message'
    allow(controller).to receive(:errors_for_display).and_return(msg)
    expect(controller.send(:try_to_save, obj, 'blah')).to eq(false)
    expect(flash[:error]).to eq(msg)
  end

end
