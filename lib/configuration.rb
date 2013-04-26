require 'jammit_helper'
require 'last_modified_or_deployed'
require 'metriks'
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
        require 'socket'

        prefix   = ENV['LIBRATO_METRICS_PREFIX']
        source   = Socket.gethostname
        on_error = ->(e) do STDOUT.puts("LibratoMetrics: #{ e.message }") end
        Metriks::Reporter::LibratoMetrics.new(user, token,
                                              prefix:   prefix,
                                              on_error: on_error,
                                              source:   source).start
      end
    end
  end
end
