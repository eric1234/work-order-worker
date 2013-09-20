# https://github.com/RESTFest/2013-greenville/wiki/Work%20order
require 'addressable/uri'
require 'status'

class WorkOrder
  def self.content_type
    'application/vnd.mogsie.work-order+json'
  end

  attr_reader :base_uri

  def initialize(attributes, base_uri)
    @attributes = attributes || {}
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
    puts 'Already started.' and return true if started?
    
    begin 
      response = post(start_uri)
   
      @started = (200...299).include?(response.code.to_i).tap do
        if response.body && response.headers['Content-Type'] == self.class.content_type
          @attributes = JSON.parse(response.body)
          puts "Work order updated to: #{@attributes.inspect}"
        end
      end
    rescue StandardError => e
      puts e.message
      false
    end
  end
  
  def status(options = {})
    check_started
    
    Status.new(status_uri).tap do |status|
      if status.ok?
        status.update(options)
      else
        raise WorkStopped, status.full_message if @cancelled = status.cancelled?
      end
    end
  end
  
  def complete(result = nil)
    check_started
    body = Addressable::URI.form_encode(result) if result
    args = [complete_uri]
    args |= [{body: body, content_type: 'application/x-www-form-urlencoded'}] if body 

    response = post(*args)
    @completed = (200...299).include?(response.code.to_i).tap { |success| fail unless success }
  end
  
  def fail(reason = nil)
    check_started
    args = [fail_uri]
    args |= [body: reason] if reason

    @failed = true
    post(*args) rescue false
  end
  
  private
    
  def start_uri
    build_uri('start')
  end

  def fail_uri
    build_uri('fail')
  end
  
  def complete_uri
    build_uri('complete')
  end
  
  def status_uri
    build_uri('status')
  end
  
  def build_uri(type)
    uri = @attributes[type] && Addressable::URI.parse(@attributes[type])
    
    if uri
      uri = Addressable::URI.join(base_uri, uri) unless uri.absolute?
      uri.to_s
    end
  end
    
  def check_started
    raise 'Work not started. Call #start first.' unless started?
  end
  
  def post(uri, options = {})
    RestClient.post(uri, options.delete(:body), options) if uri
  end
  
  def get(uri)
    RestClient.get(uri, accept: self.class.content_type) if uri
  end
  
  def reset
    @started = false
    @completed = false
    @failed = false
    @cancelled = false
  end

  class WorkStopped < StandardError; end
end

