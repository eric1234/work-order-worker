require 'net/http'

class WorkOrder
  attr_reader :base_uri
  
  def initialize(attributes, base_uri)
    @attributes = attributes
    @base_uri = base_uri
  end
  
  def type
    @attributes['type']
  end
  
  def input
    @attributes['input']
  end
  
  def started?
    @started == true
  end
  
  def start
    return if @started
    
    response = post(@attributes['start'])
    @started = (200...299).include?(response.code.to_i)
  end
  
  def status
    response = get(@attributes['status'])
    if response.body.status == 'ok'
      true
    else
      raise WorkStopped, response.body.inspect
    end
  end
  
  def complete(result = nil)
    check_started
    
    response = post(@attributes['complete'], result || {})
    fail unless (200...299).include?(response.code.to_i)
  end
  
  def fail
    check_started
    
    post(@attributes['fail'])
  end
  
  private
  def check_started
    raise 'Work not started. Call #start first.' unless started?
  end
  
  def post(path, body = nil)
    uri = URI.join(base_uri, path)
    
    Net::HTTP.post_form(uri, body ? {'body' => body} : {})
  end
  
  def get(path)
    uri = URI.join(base_uri, path)
    Net::HTTP.get(uri)
  end

  class WorkStopped < StandardError; end
end

