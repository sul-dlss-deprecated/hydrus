require 'spec_helper'

describe Hydrus::Item do

  before(:each) do
    @hi      = Hydrus::Item.new
    @dru     = 'druid:oo000oo0001'
    @apo_pid = 'druid:oo000oo0002'
    @workflow_xml = <<-END
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <workflows objectId="druid:oo000oo0001">
        <workflow repository="dor" objectId="druid:oo000oo0001" id="sdrDepositWF">
          <process datetime="1234" name="start-deposit"/>
          <process datetime="9999" name="submit"/>
          <process datetime="1234" name="approve"/>
          <process datetime="1234" name="start-accession"/>
        </workflow>
      </workflows>
    END
    @workflow_xml = noko_doc(@workflow_xml)
  end
  
  it "submit_time() should return the expect value from the workflow XML" do
    mock_wf = double('fake_workflows', :ng_xml => @workflow_xml)
    @hi.stub(:workflows).and_return(mock_wf)
    @hi.submit_time.should == "9999"
  end

end
