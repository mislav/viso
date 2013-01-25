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
            EmojiedHTML.new(downloaded).render
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
          .markdown ).include? extension
    end

  private

    def extension
      @url and File.extname(@url).downcase
    end
  end

  class EmojiedHTML
    attr_reader :content

    def initialize(content)
      @content = content
    end

    def render
      content.gsub(/:([a-z0-9\+\-_]+):/) do |match|
        if Emoji.include?($1)
          emoji_image_tag($1)
        else
          match
        end
      end
    end

  private

    def emoji_image_tag(name)
      %{<img alt="#{ name }" src="/images/emoji/#{ name }.png" width="20" height="20" class="emoji" />}
    end
  end

  # TODO: This is just a spike.
  class PygmentizedHTML < Redcarpet::Render::HTML
    def block_code(code, language)
      Content::Code.highlight code, language
    end
  end
end
