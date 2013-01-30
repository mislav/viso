require 'em-synchrony'
require 'em-synchrony/em-http'
require 'yajl'
require 'drop'

class DropFetcher
  class NotFound < StandardError; end

  attr_reader :api_host, :drop_factory, :response_parser, :logger

  def initialize(options)
    @api_host = options.fetch(:api_host)
    @drop_factory = options.fetch(:drop_factory, Drop.method(:new))
    @response_parser = options.fetch(:response_parser, Yajl::Parser.method(:parse))
    @logger = options.fetch(:logger, $stdout.method(:puts))
  end

  def api_url(path)
    File.join('http://', api_host, path.to_s)
  end

  def fetch(slug)
    data = fetch_content(slug)
    drop_factory.call(slug, parse_content(data))
  end

  def parse_content(data)
    response_parser.call(data, :symbolize_keys => true)
  end

  def http_request(url)
    EM::HttpRequest.new(url)
  end

  def record_view(slug)
    http = http_request(api_url(slug) + "/view").apost
    http.callback {
      if http.response_header.status != 201
        log_error(http,last_effective_url, http.response_header.status)
      end
    }
    http.errback {
      log_error(http,last_effective_url, 'ERR')
    }
  end

  def fetch_content(slug)
    request = http_request(api_url(slug)).get(:head => {'Accept'=> 'application/json'})
    raise NotFound unless request.response_header.status == 200
    request.response
  end

  def log_error(last_url, status)
    logger.call [ '#' * 5, last_url, status, '#' * 5 ].join(' ')
  end

end
