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

  let(:status_json) do
    <<-JSON
      { "status" : {
          "state" : "ok",
          "progress" : "2/73",
          "message" : "Checking out source code"
        }
      } 
    JSON
  end

  let(:work_order_hash) { JSON.parse(work_order_json) }

  let(:status_hash) { JSON.parse(status_json) }
  
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
  
  describe '#status' do
    def stub_get_status(response)
      stub_request(:get, 'http://status-server.example.com/203009179793/status').to_return(response)
    end

    def stub_post_status(response, body)
      stub_request(:post, 'http://status-server.example.com/203009179793/status').with(body).to_return(response)
    end
    
    it 'returns the state of the status if ok' do
      stub_get_status(status: 200, body: status_hash)
      status = status_hash.dup
      status['status']['progress'] = 'progress'
      status['status']['message'] = 'message'
      
      stub_post_status({status: 200}, {body: status})
      
      work_order.status({progress: 'progress', message: 'message'}).should == status_hash['status']['state']
    end
    
    it 'updates the status when given progress or a message' do
      stub_get_status(status: 200, body: status_hash)
    end
    
    it 'raises an error if the status is cancelled' do
      status = status_hash.dup
      status['status']['state'] = 'cancelled'
      stub_get_status(status: 200, body: status)
      
      expect { work_order.status }.to raise_error(WorkOrder::WorkStopped, status.inspect)
    end
  end

  describe '#complete' do
    let(:result) { { result: 'some_result' } }
    let(:body) { 'result=some_result' }
    
    def stub_complete(response, body = nil)
      @stub = stub_request(:post, 'http://example.org/work-orders/31789abc/completed').with(body ? {body: body} : {}).to_return(response)
    end
    
    context 'with worker started' do
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
        stub_complete({status: 200}, body)
  
        work_order.complete(result).should be_true
      end
    end

    it 'raises an error if the work is not started' do
      expect { work_order.complete }.to raise_error('Work not started. Call #start first.')
    end
  end

  describe '#fail' do
    let(:reason) { {reason: 'some_reason'} }
    let(:body) { 'reason=some_reason' }

    def stub_fail(response, body = nil)
      @stub = stub_request(:post, 'http://example.org/work-orders/31789abc/failed').with(body ? {body: body} : {}).to_return(response)
    end

    context 'with worker started' do
      before do
        work_order.stub(:started?).and_return(true)
      end

      after do
        @stub.should have_been_requested
      end

      it 'returns true it returns true if successful' do
        stub_fail(status: 200)

        work_order.fail.should be_true
      end

      it 'sends a reason' do
        stub_fail({status: 200}, body)

        work_order.fail(reason).should be_true
      end
    end

    it 'raises an error if the work is not started' do
      expect { work_order.fail }.to raise_error('Work not started. Call #start first.')
    end
  end
end
