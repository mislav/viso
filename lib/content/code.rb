require 'em-synchrony'
require 'connection_pool'
require 'pygments.rb'

class Content
  module Code
    # Used by Markdown fenced code blocks. It's already run inside a Defer block
    # so no need to defer here.
    def self.highlight(code, lexer_alias)
      lexer = ::Pygments::Lexer.find lexer_alias
      Code::Pygments.highlight code, lexer
    end

    def content
      return super unless code?
      return large_content if code_too_large?

      EM::Synchrony.defer {
        Code::Pygments.highlight raw, lexer
      }
    end

    def code?
      lexer && (lexer.aliases & %w( text postscript minid )).empty?
    end

    def lexer
      ::Pygments::Lexer.find_by_extname extension
    end

    def code_too_large?
      raw.size >= 100_000
    end

    def large_content
      %{<div class="highlight"><pre><code>#{ escaped_raw }</code></pre></div>}
    end

    def extension
      @url and File.extname(@url).downcase
    end

  private

    class Pygments
      include ::Pygments::Popen

      # Instrument how many connections are in use and count the number of
      # timeouts.
      @pool = ConnectionPool.new(size: 5, timeout: 5) {
        Content::Code::Pygments.new
      }

      def self.highlight(code, lexer)
        @pool.with do |pygments|
          options = {}
          options[:lexer] = lexer.aliases.first if lexer
          pygments.highlight code, options
        end
      end
    end
  end
end
