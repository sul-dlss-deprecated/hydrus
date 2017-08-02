require 'spec_helper'

describe ApplicationController, :type => :controller do

  it "should have the correct layout name" do
    expect(controller.layout_name).to eq('sul_chrome/application')
  end

  it "can exercise errors_for_display()" do
    obj = double('mock-object')
    msgs = {
      :files => ['foo bar', 'fubb'],
      :title => ['blah blah'],
    }
    exp = 'Files foo bar, fubb.<br />Title blah blah.'
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
