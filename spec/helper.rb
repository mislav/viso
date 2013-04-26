# Something is requiring typhoeus from rubygems and I can't figure it out.
# Need to call Bundler.setup to prevent access to rubygems.
require 'bundler'
Bundler.setup

require 'support/rspec'

ENV['RACK_ENV'] = 'test'

# Wrong (specifically ParseTreet) isn't compatible with ruby 1.9.3. Create an
# #assert method to ease porting specs to proper RSpec matchers.
module RSpec
  module Core
    class ExampleGroup
      def deny(&assertion)
        assertion.call.should_not be_true
      end

      def assert(&assertion)
        assertion.call.should be_true
      end
    end
  end
end
