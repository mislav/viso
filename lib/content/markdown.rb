require 'cgi'
require 'content/emoji'
require 'em-synchrony'
require 'redcarpet'

class Content
  module Markdown
    def content
      return super unless markdown?

      # Both EM::Synchrony.defer and #raw call Fiber.yield so they can't be
      # nested. Download content outside the .defer block.
      downloaded = raw

      EM::Synchrony.defer {
        renderer = EmojiedPygmentizedHTML.new(filter_html: true)
        Redcarpet::Markdown.
          new(renderer, fenced_code_blocks: true,
                        tables:             true,
                        strikethrough:      true,
                        no_intra_emphasis:  true).
          render(downloaded)
      }
    end

    def markdown?
      %w( .md
          .mdown
          .markdown
          .txt ).include? extension
    end

  private

    def extension
      @url and File.extname(@url).downcase
    end
  end

  class EmojiedPygmentizedHTML < Redcarpet::Render::HTML
    def self.asset_host
      @asset_host ||= [ ENV.fetch('CLOUDFRONT_DOMAIN'),
                        ENV.fetch('RAILS_ASSET_ID') ].join('/')
    end
    class << self
      attr_writer :asset_host
    end

    def block_code(code, language)
      Content::Code.highlight(code, language)
    end

    def header(text, header_level)
      %{<h#{header_level}>#{emojify(text)}</h#{header_level}>}
    end

    def paragraph(text)
      %{<p>#{emojify(text)}</p>}
    end

    def list_item(text, list_type)
      %{<li>#{emojify(text)}</li>}
    end

  private

    def emojify(text)
      text.gsub(/:([a-z0-9\+\-_]+):/) do |match|
        if Emoji.include?($1)
          emoji_image_tag($1)
        else
          match
        end
      end
    rescue ArgumentError
      text
    end

    def asset_host
      self.class.asset_host
    end

    def emoji_image_tag(name)
      file_name = "#{CGI.escape(name)}.png"
      %{<img alt="#{name}" src="//#{asset_host}/images/emoji/#{file_name}" } +
        %{width="20" height="20" class="emoji" />}
    end
  end
end
