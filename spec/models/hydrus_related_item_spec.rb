require 'spec_helper'

describe Hydrus::RelatedItem do
  subject { Hydrus::RelatedItem.new :title => 'Item Title', :url => 'http://example.com' }

  it "should have a #title accessor" do
    subject.title.should == "Item Title"
  end

  it "should have a #url accessor" do
    subject.url.should == "http://example.com"
  end

  describe ".new_from_node" do
   
    subject { Hydrus::RelatedItem.new_from_node(related_item_node) }
    context "Complete record" do
 let(:related_item_node) { Nokogiri::XML <<eos
           <relatedItem>
            <titleInfo>
              <title>Learn VB in 1 Day</title>
            </titleInfo>
            <location>
              <url>http://example.com</url>
            </location>
          </relatedItem>
eos
}
    it "should have a title and url" do
      subject.title.should == "Learn VB in 1 Day"
      subject.url.should == "http://example.com"
    end
  end

     context "Record without a title" do
 let(:related_item_node) { Nokogiri::XML <<eos
           <relatedItem>
            <titleInfo>
            </titleInfo>
            <location>
              <url>http://example.com</url>
            </location>
          </relatedItem>
eos
}
    it "should have a title and url" do
      subject.title.should == subject.url
      subject.url.should == "http://example.com"
    end
  end

       context "Record without a url" do
 let(:related_item_node) { Nokogiri::XML <<eos
           <relatedItem>
            <titleInfo>
            </titleInfo>
            <location>
            </location>
          </relatedItem>
eos
}
    it "should have a title and url" do
      subject.title.should be_empty
      subject.url.should be_empty
    end
  end

  end
end
