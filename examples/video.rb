$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'base_worker'
require 'open-uri'
require 'open3'

class Video < BaseWorker

  def initialize queue_url
  end

  def desired_task
    "http://mogsie.com/2013/workflow/video"
  end

  def work_implementation job
    source = job.input['source_url']
    input = File.basename URI(source).path
    output = input.split('.')[0..-2].join('.')+'.m4v'
    File.open input, 'wb' do |io|
      io.write open(source).read
    end
    duration = nil
    current = 0
    job.status message: "Starting"
    Open3.popen3 "ffmpeg -i #{input} -strict -2 #{output}" do |stdin, stdout, stderr|
      while status = stderr.gets
        if status =~ /invalid data/i
          FileUtils.rm input
          job.status message: "Invalid video"
          job.fail
          return
        end
        if !duration && status =~ /Duration\: (\d{2}:\d{2}:\d{2}.\d{2})/
          duration = timestamp_to_sec $1
          job.status progress: "0/#{duration}", message: "Converting"
        end
        if status =~ /time=(\d{2}:\d{2}:\d{2}.\d{2})/
          current = timestamp_to_sec $1
          job.status progress: "#{current}/#{duration}"
        end
      end
      stdout.read
    end
    job.status progress: "#{duration}/#{duration}", message: "Uploading"
    RestClient.post job.input['destination_url'], open(output).read
    FileUtils.rm input
    FileUtils.rm output
    job.status message: "Done"
    job.complete
  end

  private

  def timestamp_to_sec timestamp
    if timestamp =~ /(\d{2}):(\d{2}):(\d{2}).(\d{2})/
      "0.#{$4}".to_f + $3.to_i + $2.to_i * 60 * $1.to_i * 60 * 60
    else
      0
    end
  end
end

Video.new "http://10.0.12.137:1234/video/input-queue"
