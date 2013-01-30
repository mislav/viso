require 'content/raw'
require 'content/code'
require 'content/markdown'
require 'rack/utils'

class Content

  include Raw
  include Code
  include Markdown

  def initialize(drop)
    @drop = drop
  end

  def url
    @drop.remote_url
  end

  def asset_host
    @drop.asset_host
  end

  def extension
    url and File.extname(url).downcase
  end

  def raw
    # Files uploaded to S3 don't have a character encoding. Have to incorrectly
    # assume that everything will use UTF-8 until a proper solution for sending
    # the encoding along with the file is discovered and implemented.
    @raw ||= begin
               Metriks.timer('download-content').time {
                 EM::HttpRequest.new(url).get(:redirects => 3).response.
                   force_encoding(Encoding::UTF_8)
               }
             end
  end

  def escaped_raw
    Rack::Utils.escape_html raw
  end

end
