require 'content/raw'

describe Content::Raw do
  before do
    class FakeContent
      include Content::Raw

      def initialize(url) @url = url end
      def raw() 'Chapter 1' end
      alias_method :escaped_raw, :raw
    end
  end

  after { Object.send :remove_const, :FakeContent }

  describe '#content' do
    it 'returns raw content' do
      drop     = FakeContent.new 'http://cl.ly/hhgttg/chapter1.txt'
      expected = %{<pre><code>Chapter 1</code></pre>}

      drop.content.should == expected
    end

    it 'escapes html in content' do
      drop = FakeContent.new 'http://cl.ly/hhgttg/chapter1.txt'
      drop.stub :escaped_raw => 'escaped'
      expected = %{<pre><code>escaped</code></pre>}

      drop.content.should == expected
    end
  end
end
