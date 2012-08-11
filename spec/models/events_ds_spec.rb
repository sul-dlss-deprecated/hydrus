require 'spec_helper'

describe Hydrus::EventsDS do

  before(:all) do
    @ds_start="<events>"
    @ds_end="</events>"
    xml = <<-EOF
      #{@ds_start}
        <event type="hydrus" who="sunetid:foo" when="2011">blah</event>
        <event type="hydrus" who="sunetid:foo" when="2012">blort</event>
        <event type="hydrus" who="sunetid:bar" when="2013">blubb</event>
        <event type="other"  who="sunetid:bar" when="2014">fubb</event>
      #{@ds_end}
    EOF
    @dsdoc = Hydrus::EventsDS.from_xml(xml)
  end
  
  it "should get expected values from OM terminology" do
    tests = [
      [[:event],        %w(blah blort blubb fubb)],
      [[:event, :type], %w(hydrus hydrus hydrus other)],
      [[:event, :who],  %w(sunetid:foo sunetid:foo sunetid:bar sunetid:bar)],
      [[:event, :when], %w(2011 2012 2013 2014)],
    ]
    tests.each do |terms, exp|
      @dsdoc.term_values(*terms).should == exp
    end
  end

  it "the blank template should match our expectations" do
    exp_xml = %Q(
      #{@ds_start}
      #{@ds_end}
    )
    exp_xml = noko_doc(exp_xml)
    dsdoc = Hydrus::EventsDS.new(nil, nil)
    dsdoc.ng_xml.should be_equivalent_to exp_xml
  end

  it "Should be able to insert new event nodes" do
    events = [
      '<event type="hydrus" who="sunetid:foo" when="2011">blah</event>',
      '<event type="other"  who="sunetid:bar" when="2014">fubb</event>',
    ]
    exp_xml = noko_doc([@ds_start, events, @ds_end].flatten.join '')
    @dsdoc = Hydrus::EventsDS.from_xml("#{@ds_start}#{@ds_end}")
    @dsdoc.add('blah', :who => 'sunetid:foo', :when => '2011')
    @dsdoc.add('fubb', :who => 'sunetid:bar', :when => '2014', :type => 'other')
    @dsdoc.ng_xml.should be_equivalent_to exp_xml
  end

end
