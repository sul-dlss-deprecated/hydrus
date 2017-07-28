require 'spec_helper'

describe Hydrus::RelatedItem, type: :model do

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
      expect(ri.title).to eq('TITLE1')
      expect(ri.url).to   eq('URL1')
    end

    it "should get title from url if title is missing" do
      ri = Hydrus::RelatedItem.new_from_node(@ri_nodes[1])
      expect(ri.title).to eq('URL2')
      expect(ri.url).to   eq('URL2')
    end

    it "should get empty strings if all info is missing" do
      ri = Hydrus::RelatedItem.new_from_node(@ri_nodes[2])
      expect(ri.title).to eq('')
      expect(ri.url).to   eq('')
    end

  end

  describe "other..." do

    subject { Hydrus::RelatedItem.new title: 'Item Title', url: 'http://example.com' }

    it "should have a #title accessor" do
      expect(subject.title).to eq("Item Title")
    end

    it "should have a #url accessor" do
      expect(subject.url).to eq("http://example.com")
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
          expect(subject.title).to eq("Learn VB in 1 Day")
          expect(subject.url).to eq("http://example.com")
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
          expect(subject.title).to eq(subject.url)
          expect(subject.url).to eq("http://example.com")
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
          expect(subject.title).to be_empty
          expect(subject.url).to be_empty
        end
      end

    end

  end

end
