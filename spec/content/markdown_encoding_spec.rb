# encoding: utf-8
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
    context 'emoji' do
      it 'does not interpolate when encountering encoding errors' do
        EM.synchrony do
          content = "marohni\xE6"
          drop = FakeContent.new('http://cl.ly/hhgttg/chapter1.md', content)
          EM.stop
        end
      end
    end
  end
end

