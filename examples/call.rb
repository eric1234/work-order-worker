$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'base_worker'

require 'uri'
require 'twilio-ruby'
require 'dotenv'
Dotenv.load

class Call < BaseWorker

  def desired_task
    "http://mogsie.com/2013/workflow/call"
  end

  def work_implementation job
    client.account.calls.create from: '+12392498557', to: job.input['to'],
      method: 'GET',
      url: "http://twimlets.com/message?Message%5B0%5D=#{URI.escape job.input['text']}"
    job.complete
  end

  private

  def client
    @client ||= Twilio::REST::Client.new ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_TOKEN']
  end
end

Call.new "http://10.0.12.137:1234/call/input-queue"
