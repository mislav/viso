require 'content/emoji'
require 'em-synchrony'
require 'metriks'
require 'redcarpet'

class Content
  module Markdown
    def content
      return super unless markdown?
      Metriks.timer('markdown').time {
        # Both EM::Synchrony.defer and #raw call Fiber.yield so they can't be
        # nested. Download content outside the .defer block.
        downloaded = raw

        EM::Synchrony.defer {
          emojied = Metriks.timer('markdown.emoji').time {
            EmojiedHTML.new(asset_host).render(downloaded)
          }

          Redcarpet::Markdown.
            new(PygmentizedHTML, fenced_code_blocks: true).
            render(emojied)
        }
      }
    end

    def markdown?
      %w( .md
          .mdown
          .markdown
          .txt ).include? extension
    end
  end

  EmojiedHTML = Struct.new(:asset_host) do
    def render(content)
      content.gsub(/:([a-z0-9\+\-_]+):/) do |match|
        name = $1
        Emoji.include?(name) ? emoji_image_tag(name) : match
      end
    rescue ArgumentError
      content
    end

    def emoji_image_tag(name)
      %{<img alt="#{name}" src="//#{asset_host}/images/emoji/#{name}.png" width="20" height="20" class="emoji" />}
    end
  end

  # TODO: This is just a spike.
  class PygmentizedHTML < Redcarpet::Render::HTML
    def block_code(code, language)
      Content::Code.highlight code, language
    end
  end
end
