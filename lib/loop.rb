require 'uri'
require 'json'
require 'rest_client'

# Class this module is included in should define the following methods:
#
# * queue_url - The uri of the queue to query
# * desired_task - The task the class is looking for
# * start - Will start the process actually running the worker
#
# The class should do any sort of initilization it need to do then
# call run to start waiting for jobs.
module Loop

  def poll_queue
    loop do
      site[queue_uri.path].get accept: :json do |response, request, result|
        if result.code == '200'
          jobs = JSON.parse(response)['collection']['items']
          for job in jobs
            site[job['href']].get accept: :json do |response, request, result|
              if result.code == '200'
                job = WorkOrder.new JSON.parse(response), base_uri
                work job if job.type == desired_task
              end
            end
          end
        end
      end
      sleep poll_interval
    end
  end

  def queue_uri
    @queue_uri ||= URI queue_url
  end

  def base_uri
    "#{queue_uri.scheme}://#{queue_uri.host}:#{queue_uri.port}"
  end

  def site
    @site ||= RestClient::Resource.new base_uri
  end

  # Defaults to 2 seconds but class can override
  def poll_interval
    2
  end

end
