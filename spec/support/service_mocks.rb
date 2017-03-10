require 'webmock'
module ServiceMocks
  extend WebMock::API
  
  def self.mock
    WebMock.disable_net_connect!(allow: ['127.0.0.1', 'localhost'])

    %w(oo000oo0000 oo000oo0001 oo000oo0002 oo000oo0003 oo000oo0004 oo000oo0005 oo000oo0006 oo000oo0007
    oo000oo0008 oo000oo0009 oo000oo0010 oo000oo0011 oo000oo0012 oo000oo0013 oo000oo0098 oo000oo0099).each do |id|
      stub_request(:get, "http://sul-lyberservices-dev.stanford.edu/workflow/dor/objects/druid:#{id}/workflows/").
      with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workflows objectId="druid:oo000oo0000">
    <workflow repository="dor" objectId="druid:oo000oo0000" id="hydrusAssemblyWF">
        <process priority="0" laneId="default" elapsed="0.0" attempts="0" datetime="2017-03-08T12:11:17-0800" status="completed" name="approve"/>
        <process priority="0" laneId="default" elapsed="0.0" attempts="0" datetime="2017-03-08T12:11:17-0800" status="completed" name="submit"/>
        <process priority="0" lifecycle="registered" laneId="default" elapsed="0.0" attempts="0" datetime="2017-03-08T12:11:17-0800" status="completed" name="start-deposit"/>
        <process priority="0" laneId="default" elapsed="0.0" attempts="0" datetime="2017-03-08T12:11:17-0800" status="waiting" name="start-assembly"/>
    </workflow>
</workflows>
'                , :headers => {})


      stub_request(:get, "http://sul-lyberservices-dev.stanford.edu/workflow/dor/objects/druid:#{id}/lifecycle").
      with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => "", :headers => {})

      stub_request(:delete, "http://sul-lyberservices-dev.stanford.edu/workflow/dor/objects/druid:#{id}/workflows/hydrusAssemblyWF").
        with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => "", :headers => {})

      stub_request(:put, "http://sul-lyberservices-dev.stanford.edu/workflow/dor/objects/druid:#{id}/workflows/hydrusAssemblyWF?create-ds=true").
        # 0005 had status = "waiting"
        # with(:body => "<?xml version=\"1.0\"?>\n<workflow>\n  <process name=\"start-deposit\" status=\"completed\" lifecycle=\"registered\" laneId=\"default\"/>\n  <process name=\"submit\" status=\"completed\" laneId=\"default\"/>\n  <process name=\"approve\" status=\"completed\" laneId=\"default\"/>\n  <process name=\"start-assembly\" status=\"waiting\" laneId=\"default\"/>\n</workflow>\n",
        #      :headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate', 'Content-Length'=>'334', 'Content-Type'=>'application/xml', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => "", :headers => {})

      stub_request(:delete, "http://sul-lyberservices-dev.stanford.edu/workflow/dor/objects/druid:#{id}/workflows/versioningWF").
        with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => "", :headers => {})
    end

    stub_request(:get, "http://sul-lyberservices-dev.stanford.edu/workflow/workflow_archive?count-only=true&repository=dor&workflow=hydrusAssemblyWF").
      with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => '<objects count="1669"/>', :headers => {})

    stub_request(:get, "http://sul-lyberservices-dev.stanford.edu/workflow/workflow_archive?count-only=true&repository=dor&workflow=versioningWF").
      with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => '<objects count="11"/>', :headers => {})


  end
end
