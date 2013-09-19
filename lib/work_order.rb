require 'net/http'

class WorkOrder
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
  
  def start
    response = post @attributes['start']
    
    if response.status == 409
      raise WorkStpopped
    else
      @started = true
    end
  end
  
  def status
    response = get @attibutes['status']
    if response.body.status == 'ok'
      
    else
      raise WorkStopped
    end
  end
  
  def complete(result)
    post @attibutes['complete'], result
  end
  
  def fail
    post @attributes['fail']
  end
  
  private
  
  def post(path, body = nil)
    Net::HTTP.post(base_uri, path)
  end
  
  def get(path)
    Net::HTTP.get(base_uri, path)
  end
end

class WorkStopped < StandardError; end
