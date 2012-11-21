require 'spec_helper'

describe HyTime do

  it "should be able to exercise HyTime.now" do
    HyTime.now.should be_kind_of(DateTime)
  end

  it "should be able to exercise the generated HyTime methods" do
    HyTime::DT_FORMATS.keys.each do |f|
      s1 = HyTime.send(f)
      s2 = HyTime.send("now_#{f}")
      s1.should be_instance_of(String)
      s2.should be_instance_of(String)
    end
  end

  it "should be able to exercise the generated HyTime.* methods" do
    HyTime::DT_FORMATS.keys.each do |f|
    end
  end

  describe "HyTime.formatted()" do

    it "should get expected formatted datetimes using either a String or a DateTime" do
      # Create a time as a String and as a DateTime.
      pf  = :datetime_full
      dt1 = '2000-01-02T03:04:05.006Z'
      dt2 = DateTime.strptime(dt1, HyTime::DT_FORMATS[pf])
      # Expected formatted strings.
      exp = {
        # Back-end formats: in UTC.
        :date             => '2000-01-02',
        :time             => '03:04:05Z',
        :datetime         => '2000-01-02T03:04:05Z',
        pf                => dt1,
        # Display formats should be 8 hours in the past relative to UTC.
        :date_display     => '2000-01-01',
        :time_display     => '19:04:05',
        :datetime_display => '2000-01-01 19:04:05',
      }
      exp.each do |f, e|
        # String, with and without a :parse format.
        HyTime.formatted(dt1, :parse => pf, :format => f).should == e
        HyTime.formatted(dt1, :format => f).should == e
        # DateTime.
        HyTime.formatted(dt2, :format => f).should == e
      end
    end
    
    it "should use :datetime as the default output format" do
      dt = '2000-01-02T03:04:05Z'
      HyTime.formatted(dt).should == dt
      HyTime.formatted(dt, :format => :time_display).should  == '19:04:05'
      HyTime.formatted('2000-01-02', :parse => :date).should == '2000-01-02T00:00:00Z'
    end
    
    it "should return empty string if given a blank value" do
      HyTime.formatted(nil).should == ''
      HyTime.formatted('').should  == ''
    end
    
  end

end
