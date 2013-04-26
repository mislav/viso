# Viso
# ------
#
# **Viso** is the magic that powers [CloudApp][] by displaying shared Drops. At
# its core, **Viso** is a simple [Sinatra][] app that retrieves a **Drop's**
# details using the [CloudApp API][]. Images are displayed front and center,
# bookmarks are redirected to their destination, markdown is processed by
# [RedCarpet][], code files are highlighted by [Pygments], and, when all else
# fails, a download button is provided. **Viso** uses [eventmachine][] and
# [rack-fiber_pool][] to serve requests while expensive network I/O is performed
# asynchronously.
#
# [cloudapp]:        http://getcloudapp.com
# [sinatra]:         https://github.com/sinatra/sinatra
# [cloudapp api]:    http://developer.getcloudapp.com
# [redcarpet]:       https://github.com/tanoku/redcarpet
# [pygments]:        http://pygments.org
# [eventmachine]:    https://github.com/eventmachine/eventmachine
# [rack-fiber_pool]: https://github.com/mperham/rack-fiber_pool
require 'addressable/uri'
require 'eventmachine'
require 'metric_recorder'
require 'sinatra/base'
require 'simpleidn'

require 'configuration'
require 'drop'
require 'drop_fetcher'
require 'drop_presenter'
require 'domain'
require 'domain_fetcher'

require 'base64'

class Viso < Sinatra::Base
  register Configuration

  # The home page. Custom domain users have the option to set a home page so
  # ping the API to get the home page for the current domain. Response is cached
  # for one hour.
  get '/' do
    cache_duration 3600
    redirect DomainFetcher.fetch(env['HTTP_HOST']).home_page, 301
    ## Last-Modified
  end

  # Record metrics sent by JavaScript clients.
  get '/metrics' do
    MetricRecorder.record params['name'], params['value']
    content_type 'text/javascript'
    cache_duration 0
    status 200
  end

  # The main responder for a **Drop**. Responds to both JSON and HTML and
  # response is cached for 15 minutes.
  get %r{^                         #
         (?:/(text|code|image))?   # Optional drop type
         /([^/?#]+)                # Item slug
         (?:                       #
           /  |                    # Ignore trailing /
           /o                      # Show original image size
         )?                        #
         $}x do |type, slug|
    fetch_and_render_drop slug
  end

  get %r{^
         (?:/(?:text|code|image))?  # Optional drop type
         /([^/?#]+)                 # Item slug
         (?:/o)?                    # Show original image size
         /status                    #
         $}x do |slug|
    fetch_and_render_status slug
  end

  # Legacy endpoint used at one time for A/B performance testing. It was only
  # active for 24 hours but it lives on embedded on websites. Keep this around
  # for a while and either roll it into the primary content route or delete it
  # if it's unused.
  get %r{^/content                #
         (?:/(text|code|image))?  # Optional drop type
         /([^/?#]+)               # Item slug
         /([^/?#]+)               # Encoded url
         $}x do |type, slug, encoded_url|
    begin
      decoded_url = Base64.urlsafe_decode64(encoded_url)
    rescue
      not_found
    end

    redirect_to_content slug, decoded_url
  end

  # The download link for a **Drop**. Response is cached for 15 minutes.
  get %r{^                         #
         (?:/(text|code|image))?   # Optional drop type
         /([^/?#]+)                # Item slug
         /download
         /(.+)       # Filename
         $}x do |type, slug, filename|
    fetch_and_download_drop slug
  end

  # The content for a **Drop**. Response is cached for 15 minutes.
  get %r{^                        #
         (?:/(text|code|image))?  # Optional drop type
         /([^/?#]+)               # Item slug
         /(.+)                    # Filename
         $}x do |type, slug, filename|
    respond_to {|format|
      format.html do
        fetch_and_render_content slug, filename
      end
      format.json do
        fetch_and_render_drop slug
      end
    }
  end

  def redirect_to_content(slug, remote_url, updated_at = nil)
    DropFetcher.record_view slug if remote_url

    cache_duration 0
    last_modified updated_at if updated_at

    not_found and return unless remote_url
    redirect remote_url, 301
  end

  def cache_duration(seconds)
    response['Date'] = Time.now.httpdate
    cache_control :public, :max_age => seconds
  end

  # Don't need to return anything special for a 404.
  not_found do
    cache_duration 0
    not_found error_content_for(:not_found)
  end

protected

  # Fetch and return a **Drop** with the given `slug`. Handle
  # `DropFetcher::NotFound` errors and render the not found response.
  def fetch_drop(slug)
    Metriks.timer('drop.fetch').time do
      DropFetcher.fetch slug
    end
  rescue DropFetcher::NotFound
    not_found
  end

  def fetch_and_render_drop(slug)
    drop = DropPresenter.new fetch_drop(slug), self
    check_domain_matches drop

    respond_to {|format|
      format.html {
        DropFetcher.record_view slug if drop.bookmark? || drop.text?
        cache_duration 0
        last_modified drop.updated_at
        drop.render_html
      }
      format.json {
        cache_duration 0
        last_modified drop.updated_at
        drop.render_json
      }
    }
  rescue => e
    env['async.callback'].call [ 500, {}, error_content_for(:error) ]
    Airbrake.notify_or_ignore e if defined? Airbrake
  end

  def fetch_and_download_drop(slug)
    respond_to {|format|
      format.html { redirect_to_api }
      format.json {
        drop = DropPresenter.new fetch_drop(slug), self
        # check_domain_matches drop
        # check_filename_matches drop, filename
        cache_duration 0
        last_modified drop.updated_at
        drop.render_json
      }
    }
  end

  def fetch_and_render_content(slug, filename)
    drop = DropPresenter.new fetch_drop(slug), self
    # check_domain_matches drop
    # check_filename_matches drop, filename
    drop.render_content
  end

  def fetch_and_render_status(slug)
    drop = DropPresenter.new fetch_drop(slug), self
    cache_duration 0
    last_modified drop.updated_at
    status drop.pending? ? 204 : 200
  end

  def error_content_for(type)
    type = type.to_s.gsub /_/, '-'
    File.read File.join(settings.public_folder, "#{ type }.html")
  end

  # Check for drops served where the drop's domain doesn't match the accessed
  # domain. For example, a user using another user's custom domain.
  def check_domain_matches(drop)
    unless custom_domain_matches? drop
      puts [ '*' * 5,
             drop.data[:url].inspect,
             env['HTTP_HOST'].inspect,
             '*' * 5
           ].join(' ')

      not_found
    end
  end

  def custom_domain_matches?(drop)
    domain   = Addressable::URI.parse(drop.data[:url]).host
    host     = env['HTTP_HOST'].split(':').first
    expected = SimpleIDN.to_ascii(domain).downcase
    actual   = SimpleIDN.to_ascii(host).downcase

    DropFetcher.default_domains.include?(actual) or
      actual == expected or
      actual.sub(/^www\./, '') == expected
  end

  # Redirect the current request to the same path on the API domain.
  def redirect_to_api
    cache_duration 3600
    redirect "http://#{ DropFetcher.base_uri }#{ request.path }", 301
  end
end
