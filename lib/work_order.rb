require 'net/http'

class WorkOrder
  attr_reader :base_uri
  
  def initialize(attributes, base_uri)
    @attributes = attributes
    @base_uri = base_uri
    reset
  end
  
  def type
    @attributes['type']
  end
  
  def input
    @attributes['input']
  end
  
  def started?
    @started
  end
  
  def completed?
    @completed
  end
  
  def cancelled?
    @cancelled
  end
  
  def failed?
    @failed
  end
  
  def start
    if @started     
      puts 'Already started.'
      return
    end
    
    response = post(@attributes['start'])
    puts response.body.inspect if response.body
    
    @started = (200...299).include?(response.code.to_i)
  end
  
  def status(options = {})
    response = get(@attributes['status'])
    state = response['status']['state']
    
    if state == 'ok'
      unless options.empty?
        
      end
      state
    else
      @cancelled = true
      raise WorkStopped, response.inspect
    end
  end
  
  def complete(result = nil)
    check_started
    
    response = post(@attributes['complete'], result || {})
    @completed = (200...299).include?(response.code.to_i).tap { |success| fail unless success }
  end
  
  def fail(reason = nil)
    check_started
    @failed = true
    
    post(@attributes['fail'], reason || {}) rescue false
  end
  
  private
  def check_started
    raise 'Work not started. Call #start first.' unless started?
  end
  
  def post(path, body = nil)
    uri = URI.join(base_uri, path)
    Net::HTTP.post_form(uri, {}.merge(body || {}))
  end
  
  def get(path)
    uri = URI.join(base_uri, path)
    Net::HTTP.get(uri)
  end
  
  def reset
    @started = false
    @completed = false
    @failed = false
    @cancelled = false
  end

  class WorkStopped < StandardError; end
end

