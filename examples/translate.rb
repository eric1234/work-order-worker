require 'cgi'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'base_worker'

class Translate < BaseWorker

  def desired_task
    "http://mogsie.com/2013/workflow/translate"
  end

  def work_implementation job
    url = "http://translate.google.com/translate_a/t?client=t&text=#{CGI::escape job.input['text']}&hl=#{job.input['to']}&sl=#{job.input['from']}&tl=#{job.input['to']}&ie=UTF-8&oe=UTF-8&multires=1&otf=1&pc=1&trs=1&ssel=3&tsel=6&sc=1"
    translated = eval(RestClient.get(url).body.gsub(/,{2,}/, ',')).first.first.first
    puts translated
    job.complete({"translated" => translated})
  end
end

Translate.new "http://10.0.12.137:1234/translate/input-queue"
