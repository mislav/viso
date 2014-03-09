require 'content/markdown'

describe Content::Markdown do
  before do
    module FakeSuper
      def content() 'super content' end
    end

    class FakeContent
      include FakeSuper
      include Content::Markdown

      attr_accessor :raw
      def initialize(url, raw = '# Chapter 1')
        @url = url
        @raw = raw
      end
    end
  end

  after do
    Object.send :remove_const, :FakeContent
    Object.send :remove_const, :FakeSuper
  end


  describe '#content' do
    it 'generates markdown' do
      EM.synchrony do
        drop = FakeContent.new 'http://cl.ly/hhgttg/chapter1.md'
        markdown = '<h1>Chapter 1</h1>'
        EM.stop

        drop.content.strip.should == markdown
      end
    end

    context 'emoji' do
      before do Content::EmojiedPygmentizedHTML.asset_host = 'emoji.com' end

      it 'interpolates emoji icons' do
        EM.synchrony do
          drop  = FakeContent.new('http://cl.ly/hhgttg/chapter1.md',
                                  '# Chapter 1 :books:')
          emoji = '<img alt="books" ' \
                  'src="//emoji.com/images/emoji/books.png" ' +
                  'width="20" height="20" class="emoji" />'
          EM.stop

          drop.content.should include(emoji)
        end
      end

      it 'escapes emoji names' do
        EM.synchrony do
          drop = FakeContent.new('http://cl.ly/hhgttg/chapter1.md',
                                 '# Chapter 1 :+1:')
          EM.stop

          content = drop.content
          content.should_not include(':+1:')
          content.should include('src="//emoji.com/images/emoji/%2B1.png"')
        end
      end

      it 'does not interpolate invalid emoji' do
        EM.synchrony do
          drop = FakeContent.new('http://cl.ly/hhgttg/chapter1.md',
                                 '# Chapter 1 :not_emoji:')
          EM.stop

          content = drop.content
          content.should include(':not_emoji:')
          content.should_not include('<img')
        end
      end
    end

    it 'calls #super for non-markdown files' do
      drop = FakeContent.new 'http://cl.ly/hhgttg/chapter1.text'
      drop.content.should == 'super content'
    end
  end

  describe '#markdown?' do
    %w( md mdown markdown txt ).each do |ext|
      it "is true when a #{ ext.upcase } file" do
        drop = FakeContent.new "http://cl.ly/hhgttg/cover.#{ ext }"
        drop.should be_markdown
      end
    end

    it 'is true when a markdown file with an upper case extension' do
      drop = FakeContent.new 'http://cl.ly/hhgttg/cover.MD'
      drop.should be_markdown
    end

    it 'is false when an image' do
      drop = FakeContent.new 'http://cl.ly/hhgttg/cover.png'
      drop.should_not be_markdown
    end

    it 'is false when pending' do
      drop = FakeContent.new nil
      drop.should_not be_markdown
    end
  end

end
