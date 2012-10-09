require 'spec_helper'

describe ApplicationHelper do

  include ApplicationHelper

  it "should get the local application name" do
    application_name.should == "Stanford Digital Repository"
  end

  it "should be able to exercise both branches of hydrus_format_date()" do
    hydrus_format_date('').should == ''
    hydrus_format_date('1999-03-31').should == 'Mar 31, 1999'
  end

  it "seen_beta_dialog? should be shown only once" do
    # Initially, we haven't seen the dialog.
    session[:seen_beta_dialog] = false
    seen_beta_dialog?.should == false
    # After seeing dialog, the flag is true.
    session[:seen_beta_dialog].should == true
    seen_beta_dialog?.should == true
  end

  it "formatted_datetime() should return formatted date strings" do
    tests = [
      ['2012-08-10T06:11:57-0700', :date,     '10-Aug-2012'],
      ['2012-08-10T06:11:57-0700', :time,     '06:11 am'],
      ['2012-08-10T06:11:57-0700', :datetime, '10-Aug-2012 06:11 am'],
      ['blah'                    , nil,        nil],
      [nil                       , nil,        nil],
    ]
    tests.each do |input, fmt, exp|
      formatted_datetime(input, fmt).should == exp
    end
  end
  
  describe "render helpers" do
    it "should return a string that corresponds to the view path for that model" do
      view_path_from_model(Hydrus::Collection.new(:pid=>"1234")).should == "hydrus_collections"
      view_path_from_model(Hydrus::Item.new(:pid=>"1234")).should       == "hydrus_items"
    end
  end

end
