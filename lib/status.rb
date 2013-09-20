# https://github.com/tavis-software/Status
require 'rest-client'

class Status
  OK, BUSY, CANCELLED, ERROR, WAITING, WARNING = %w(ok busy cancelled error waiting warning)

  def self.content_type
    'application/status+json'
  end
  
  def initialize(uri)
    @uri = uri
    load
  end
  
  def ok?
    state == OK
  end

  def cancelled?
    state == CANCELLED
  end

  def error?
    state == ERROR
  end
  
  def state
    @status['status']['state']
  end

  def progress
    @status['status']['progress']
  end

  def message
    @status['status']['message']
  end
  
  def full_message
    @status['status'].inspect
  end
  
  def update(options)
    @status['status']['progress'] = options[:progress] if options[:progress]
    @status['status']['message'] = options[:message] if options[:message]
    
    RestClient.put(@uri, @status.to_json, {'Content-Type' => self.class.content_type}) unless options.empty?
    self
  end
  
  def load
    content_type = self.class.content_type
    begin
      response = RestClient.get(@uri, accept: content_type)
      
      if response.headers[:content_type] == content_type
        @status = response.body
      else
        message = "The URI #{@uri} did not return the expected Content-Type #{self.class.content_type}. " <<
          "Returned #{response.headers['Content-Type']}."
        @status = {'status' => {'state' => 'error', 'message' => message}}
      end
    rescue StandardError => e
      @status = {'status' => {'state' => 'error', 'message' => "Loading status failed: #{e.message}."}}
    end
  end
end
