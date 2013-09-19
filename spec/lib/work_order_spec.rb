require 'spec_helper'
require 'json'

describe WorkOrder do
  let(:work_order_json) do
    <<-JSON
      {
        "type": ".../build-some-code",
        "input": {
          "source" : "https://exmample.com/example.git",
          "revision" : "463a7b891ab678ffa07bc",
          "type": "nodejs"
        },
      
        "start": "/work-orders/31789abc/take",
        "status": "http://status-server.example.com/203009179793/status",
        "complete": "/work-orders/31789abc/completed",
        "fail": "/work-orders/31789abc/failed"
      }
    JSON
  end
  
  let(:work_order_hash) { JSON.parse(work_order_json) }
  
  let(:base_uri) { 'http://example.org' }
  
  let(:work_order) { WorkOrder.new(work_order_hash, base_uri) }
  
  describe '#base_uri' do
    it 'returns the uri' do
      work_order.base_uri.should == base_uri
    end
  end
  
  describe '#start' do
    def stub_start(response)
      stub_request(:post, 'http://example.org/work-orders/31789abc/take').to_return(response)
    end
    
    it 'returns true if the work is started' do
      stub_start(status: 201)
      
      work_order.start.should be_true
    end
    
    it 'raises an error if the work is already started' do
      stub_start(status: 409)
      work_order.start.should be_false
    end
  end

  describe '#start' do
    def stub_start(response)
      stub_request(:post, 'http://example.org/work-orders/31789abc/take').to_return(response)
    end

    it 'returns true if the work is started' do
      stub_start(status: 200)

      work_order.start.should be_true
    end

    it 'raises an error if the work is already started' do
      stub_start(status: 409)
      work_order.start.should be_false
    end
  end

  describe '#complete' do
    def stub_complete(response, body = nil)
      @stub = stub_request(:post, 'http://example.org/work-orders/31789abc/completed').with(body ? {body: body} :{}).to_return(response)
    end
    
    before do
      work_order.stub(:started?).and_return(true)
    end
    
    after do
      @stub.should have_been_requested
    end

    it 'returns true it returns true if successful' do
      stub_complete(status: 200)

      work_order.complete.should be_true
    end

    it 'sends a result' do
      result = 'result'
      stub_complete({status: 200}, result)

      work_order.complete(result).should be_true
    end

    it 'raises an error if the work is already started' do
      stub_complete(status: 409)
      work_order.should_receive(:fail)
      
      work_order.complete
    end
  end
end
