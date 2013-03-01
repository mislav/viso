require 'jammit_helper'
require 'last_modified_or_deployed'
require 'metriks'
require 'sinatra/respond_with'
require 'social_helper'
require 'erb'
require 'ostruct'

module Configuration
  def self.config_file
    "config/settings.yml"
  end

  def self.registered(app)
    Configurer.new(app).inject config_file
  end

  # Runs in the context of a Sinatra application
  class Configurer < SimpleDelegator
    def inject config_file
      apply_settings(config_file)
      unversioned_file = config_file.sub(/(\.ya?ml)$/, '.local\1')
      apply_settings(unversioned_file) if File.exist? unversioned_file

      add_metriks_instrumentation
      add_new_relic_instrumentation
      catch_errors_with_airbrake
      handle_requests_using_fiber_pool

      register_response_and_view_helpers
      vary_all_responses_on_accept_header
      serve_public_assets
      log_to_stdout
      report_metrics
    end

    def apply_settings config_file
      load_settings(config_file, environment).each do |key, value|
        if value.is_a? Hash
          if existing = respond_to?(key) && send(key) and existing.is_a? OpenStruct
            value.each do |nested_key, nested_value|
              existing.send("#{nested_key}=", nested_value)
            end
          else
            value = OpenStruct.new(value)
          end
        end
        set(key, value)
      end
    end

    def load_settings file, env
      data = YAML.load ERB.new(IO.read(file)).result
      data[env.to_s]
    end

    def add_metriks_instrumentation
      require 'metriks/middleware'
      use Metriks::Middleware
    end

    def add_new_relic_instrumentation
      return unless new_relic.license_key

      configure :production do
        require 'newrelic_rpm'
      end

      configure :development do
        require 'new_relic/control'
        NewRelic::Control.instance.init_plugin 'developer_mode' => true,
          :env => 'development'

        require 'new_relic/rack/developer_mode'
        use NewRelic::Rack::DeveloperMode
      end

      configure :production, :development do
        require 'newrelic_instrumentation'
        use NewRelicInstrumentationMiddleware
      end
    end

    def catch_errors_with_airbrake
      configure :production do
        if airbrake.api_key
          require 'active_support'
          require 'active_support/core_ext/object/blank'
          require 'airbrake'

          Airbrake.configure do |config|
            config.api_key = airbrake.api_key
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

        def last_modified(modified)
          last_deployed = Time.at settings.assets.timestamp.to_i
          super(modified > last_deployed ? modified : last_deployed)
        end

        def typekit_token
          settings.typekit.token
        end
      end
    end

    def vary_all_responses_on_accept_header
      before { headers['Vary'] = 'Accept' }
    end

    def serve_public_assets
      set :root, File.expand_path('../..', settings.app_file)
      set :static_cache_control, [ :public, :max_age => assets.expires_in ]
      set :public_folder, 'public'
    end

    def log_to_stdout
      STDOUT.sync = true
    end

    def report_metrics
      if librato.user && librato.token
        require 'metriks/reporter/librato_metrics'
        require 'socket'

        source   = Socket.gethostname
        on_error = ->(e) do STDOUT.puts("LibratoMetrics: #{ e.message }") end
        Metriks::Reporter::LibratoMetrics.new(librato.user, librato.token,
                                              prefix:   librato.prefix,
                                              on_error: on_error,
                                              source:   source).start
      elsif development?
        require 'metriks/reporter/logger'
        Metriks::Reporter::Logger.new(logger:   Logger.new(STDOUT),
                                      interval: metrics.logger_interval).start
      end
    end
  end
end
