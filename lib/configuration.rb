require 'jammit_helper'
require 'last_modified_or_deployed'
require 'sinatra/respond_with'
require 'social_helper'

module Configuration
  def self.registered(subject)
    Configurer.new(subject).inject
  end

  class Configurer < SimpleDelegator
    def inject
      add_metriks_instrumentation
      catch_errors_with_airbrake
      handle_requests_using_fiber_pool

      register_response_and_view_helpers
      vary_all_responses_on_accept_header
      serve_public_assets
      log_to_stdout
      report_metrics
    end

    def add_metriks_instrumentation
      require 'metriks/middleware'
      use Metriks::Middleware
    end

    def catch_errors_with_airbrake
      configure :production do
        if ENV['AIRBRAKE_API_KEY']
          require 'active_support'
          require 'active_support/core_ext/object/blank'
          require 'airbrake'

          Airbrake.configure do |config|
            config.api_key = ENV['AIRBRAKE_API_KEY']
          end

          use Airbrake::Rack
          enable :raise_errors
        end
      end
    end

    def handle_requests_using_fiber_pool
      return if test?

      configure do
        require 'rack/fiber_pool'
        use Rack::FiberPool
      end
    end

    def register_response_and_view_helpers
      register Sinatra::RespondWith
      register JammitHelper
      register SocialHelper
      helpers do
        include Rack::Utils
        include LastModifiedOrDeployed
      end
    end

    def vary_all_responses_on_accept_header
      before { headers['Vary'] = 'Accept' }
    end

    # Cache public assets for 1 year.
    def serve_public_assets
      set :root, File.expand_path(File.join(File.dirname(settings.app_file), '..'))
      set :static_cache_control, [ :public, :max_age => 31557600 ]
      set :public_folder, 'public'
    end

    def log_to_stdout
      STDOUT.sync = true
    end

    def report_metrics
      user  = ENV['LIBRATO_METRICS_USER']
      token = ENV['LIBRATO_METRICS_TOKEN']
      if user && token
        require 'metriks/reporter/librato_metrics'

        prefix = ENV.fetch('LIBRATO_METRICS_PREFIX') do
          ENV['RACK_ENV'] unless ENV['RACK_ENV'] == 'production'
        end

        app_name = ENV.fetch('DYNO') do
          # Fall back to hostname if DYNO isn't set.
          require 'socket'
          Socket.gethostname
        end

        on_error = ->(e) do STDOUT.puts("LibratoMetrics: #{ e.message }") end
        opts     = { on_error: on_error, source: app_name }
        opts[:prefix] = prefix if prefix && !prefix.empty?
        Metriks::Reporter::LibratoMetrics.new(user, token, opts).start
      else
        require 'metriks/reporter/logger'
        Metriks::Reporter::Logger.new(logger: $stdout, interval: 10).start
      end
    end
  end
end
