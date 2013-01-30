require 'new_relic/agent/method_tracer'

Drop.class_eval do
  include NewRelic::Agent::MethodTracer

  add_method_tracer :content
  add_method_tracer :lexer_name
  add_method_tracer :raw
  add_method_tracer :parse_markdown
  add_method_tracer :highlight_code
end

DropFetcher.instance_eval do
  include NewRelic::Agent::MethodTracer

  add_method_tracer :fetch,         'Custom/DropFetcher/fetch'
  add_method_tracer :fetch_content, 'Custom/DropFetcher/fetch_drop_content'
end

class NewRelicInstrumentationMiddleware
  def initialize(downstream, options = {})
    @downstream = downstream
  end

  def call(env)
    @downstream.call env
  end
  include NewRelic::Agent::Instrumentation::Rack
end
