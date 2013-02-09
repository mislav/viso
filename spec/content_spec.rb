require 'helper'
require 'support/vcr'
require 'content'

describe Content do

  describe '#raw' do
    subject { Content.new 'http://f.cl.ly/items/hhgttg/Chapter%201.txt' }

    it 'fetches content' do
      EM.synchrony do
        VCR.use_cassette 'text' do
          subject.raw.start_with?('Chapter 1').should be_true
        end

        EM.stop
      end
    end

    it 'memoizes response' do
      EM.synchrony do
        VCR.use_cassette('text') { subject.raw }

        # Relying on VCR raise an exception if it tries to make an external API
        # call since it's called outside of a loaded cassette.
        lambda { subject.raw }.should_not raise_error

        EM.stop
      end
    end
  end

  describe '#escaped_raw' do
    subject { Content.new 'http://f.cl.ly/items/hhgttg/hello.rb' }

    it 'escapes raw content' do
      EM.synchrony do
        VCR.use_cassette 'ruby' do
          subject.escaped_raw.should == "puts &#x27;Hello, world!&#x27;\n"
        end

        EM.stop
      end
    end
  end

  describe '#content' do
    it 'integrates with Raw' do
      drop = Content.new 'http://f.cl.ly/items/hhgttg/Chapter%201.text'

      EM.synchrony do
        VCR.use_cassette 'plain_text' do
          drop.content.start_with?('<pre><code>Chapter 1').should be_true
        end

        EM.stop
      end
    end

    it 'integrates with Code' do
      drop = Content.new 'http://f.cl.ly/items/hhgttg/hello.rb'

      EM.synchrony do
        VCR.use_cassette 'ruby' do
          drop.content.should include('<div class="highlight">')
        end

        EM.stop
      end
    end

    it 'integrates with Markdown' do
      drop = Content.new 'http://f.cl.ly/items/hhgttg/Chapter%201.md'

      EM.synchrony do
        VCR.use_cassette 'markdown' do
          drop.content.start_with?('<h1').should == true
        end

        EM.stop
      end
    end
  end

end
