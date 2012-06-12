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

end
