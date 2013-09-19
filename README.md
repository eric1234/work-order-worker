# Overview

Developed for RestFEST 2013 Hackfest. A base class to make it quick and easy to write workers.
The [work server](https://github.com/RESTFest/2013-greenville/wiki/Work-order) provides a queue of jobs.
A worker will scan those jobs for ones it can handle, process the job and post the result.

This base class abstracts all the server interaction so the worker can just concern itself with
actually doing the job.

# Example

Below is an example worker that will translate text from one language to another.

        require 'cgi'
        require 'base_worker'
        
        class Translate < BaseWorker
        
          def desired_task
            "http://mogsie.com/2013/workflow/translate"
          end
        
          def work_implementation job
            url = "http://translate.google.com/translate_a/t?client=t&text=#{CGI::escape job.input['text']}&hl=#{job.input['to']}&sl=#{job.input['from']}&tl=#{job.input['to']}&ie=UTF-8&oe=UTF-8&multires=1&otf=1&pc=1&trs=1&ssel=3&tsel=6&sc=1"
            translated = eval(RestClient.get(url).body.gsub(/,{2,}/, ',')).first.first.first
            job.complete translated
          end
        end

To start up the worker run:

        Translate.new queue_uri

# Hooks

## work_implementation

The primary hook actually execute the job. This method is given an instance of `WorkOrder`. When the job is complete
it should call the `complete` method on this `WorkOrder`. If an error occurs it should call `fail` on the `WorkOrder`.
You can also update the status with the server via the `status` method.

## desired_task

The server will have a list of jobs this worker may or may not be able to handle. This hook will indicate the
jobs this worker is looking for. Will be a string in the format of a unique URL.

## poll_interval

How often to poll for new jobs. This is pre-defined to 2 seconds but you can re-define to poll more or less often.

