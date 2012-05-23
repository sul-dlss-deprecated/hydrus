require 'spec_helper'

describe("Collection view", :type => :request) do

  before :each do
    @druid = 'druid:oo000oo0003'
    @hc    = Hydrus::Collection.find @druid
  end

  it "Some of the expected info is displayed" do
    exp_content = [
      @druid,
      "SSDS Social Science Data Collection",
      "Abstract:",
    ]
    visit polymorphic_url(@hc)
    exp_content.each do |exp|
      page.should have_content(exp)
    end
  end

end
