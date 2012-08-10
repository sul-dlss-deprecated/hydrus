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

  it "formatted_date() should return formatted date strings" do
    tests = {
      '2012-08-10T09:11:57-0700' => '10-Aug-2012',
      '2011-01-01 09:11:57'      => '01-Jan-2011',
      'blah'                     => nil,
      nil                        => nil,
    }
    tests.each do |input, exp|
      formatted_date(input).should == exp
    end
  end

end
