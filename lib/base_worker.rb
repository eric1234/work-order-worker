require 'loop'
require 'work_order'

class BaseWorker
  include Loop
  
  attr_reader :queue_url
  
  def initialize(queue_url)
    @queue_url = queue_url
    poll_queue
  end
  
  def work(work_order)
    begin
      work_implementation(work_order) if work_order.start
    rescue StandardError
      work_order.fail
      raise
    end 
  end
  
  def work_implementation(work_order)
    raise 'abstract'
  end
  
  def desired_task
    raise 'abstract'
  end
end
