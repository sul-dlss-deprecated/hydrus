require 'spec_helper'

describe Hydrus::RelatedItem do
  
  describe "new_from_node()" do

    before(:all) do
      xml = <<-END
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <descMetadata>
          <relatedItem>
            <titleInfo>
              <title>TITLE1</title>
            </titleInfo>
            <location>
              <url>URL1</url>
            </location>
          </relatedItem>
          <relatedItem>
            <titleInfo>
              <title></title>
            </titleInfo>
            <location>
              <url>URL2</url>
            </location>
          </relatedItem>
          <relatedItem>
          </relatedItem>
        </descMetadata>
      END
      @ri_nodes = noko_doc(xml).xpath('//relatedItem')
    end
   
    it "should get title and url as expected" do
      ri = Hydrus::RelatedItem.new_from_node(@ri_nodes[0])
      ri.title.should == 'TITLE1'
      ri.url.should   == 'URL1'
    end

    it "should get title from url if title is missing" do
      ri = Hydrus::RelatedItem.new_from_node(@ri_nodes[1])
      ri.title.should == 'URL2'
      ri.url.should   == 'URL2'
    end

    it "should get empty strings if all info is missing" do
      ri = Hydrus::RelatedItem.new_from_node(@ri_nodes[2])
      ri.title.should == ''
      ri.url.should   == ''
    end

  end

  describe "other..." do

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
        let(:related_item_node) { Nokogiri::XML <<-eos
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
         let(:related_item_node) { Nokogiri::XML <<-eos
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
        let(:related_item_node) { Nokogiri::XML <<-eos
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

end
