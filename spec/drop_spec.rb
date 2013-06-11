require 'drop'
require 'time'

describe Drop do
  let(:data) { {} }
  subject    { Drop.new 'abc123', data }

  its(:slug) { should eq('abc123') }

  describe '#beta?' do
    it { should_not be_beta }

    context 'using the beta mac app' do
      let(:data) {{ source: 'CloudApp/2.0 beta 22 (Mac OS X 10.7.3)' }}
      it { should be_beta }
    end

    context 'using an old beta mac app' do
      let(:data) {{ source: 'Cloud/2.0 beta 22 (Mac OS X 10.7.3)' }}
      it { should be_beta }
    end

    context 'using the released mac app' do
      let(:data) {{ source: 'Cloud/1.5.3 CFNetwork/595 Darwin/12.0.0 (x86_64) (MacBook6%2C1)' }}
      it { should_not be_beta }
    end

    context 'using the cli' do
      let(:data) {{ source: 'cloudapp-gem/2.0.0.beta.7 (x86_64-darwin11.3.0) ruby/1.9.3' }}
      it { should be_beta }
    end
  end

  describe '#subscribed?' do
    it { should_not be_subscribed }

    context 'when subscribed' do
      let(:data) {{ subscribed: true }}
      it { should be_subscribed }
    end

    context 'when unsubscribed' do
      let(:data) {{ subscribed: false }}
      it { should_not be_subscribed }
    end
  end

  describe '#item_type' do
    let(:data) {{ item_type: 'bookmark' }}
    its(:item_type) { should eq('bookmark') }
  end

  describe '#pending?' do
    let(:data) {{ item_type: 'pending' }}
    it { should be_pending }
  end

  describe '#share_url' do
    let(:data) {{ url: 'http://cl.ly/hhgttg' }}
    its(:share_url) { should eq('http://cl.ly/hhgttg') }
  end

  describe '#thumbnail_url' do
    let(:data) {{ thumbnail_url: 'http://cl.ly/hhgttg' }}
    its(:thumbnail_url) { should eq('http://cl.ly/hhgttg') }
  end

  describe '#content_url' do
    let(:data) {{ content_url: 'http://cl.ly/hhgttg/chapter1.txt' }}
    its(:content_url) { should eq('http://cl.ly/hhgttg/chapter1.txt') }
  end

  describe '#download_url' do
    let(:data) {{ download_url: 'http://cl.ly/hhgttg/chapter1.txt' }}
    its(:download_url) { should eq('http://cl.ly/hhgttg/chapter1.txt') }
  end

  describe '#remote_url' do
    context 'a file' do
      let(:data) {{ remote_url: 'http://cl.ly/hhgttg/chapter1.txt' }}
      its(:remote_url) { should eq('http://cl.ly/hhgttg/chapter1.txt') }
    end

    context 'a bookmark' do
      let(:data) {{ redirect_url: 'http://cl.ly/hhgttg/chapter1.txt' }}
      its(:remote_url) { should eq('http://cl.ly/hhgttg/chapter1.txt') }
    end
  end

  describe '#name' do
    let(:data) {{ name: 'Chapter 1' }}
    its(:name) { should eq('Chapter 1') }
  end

  describe '#updated_at' do
    let(:data) {{ updated_at: Time.utc(2012).iso8601 }}
    its(:updated_at) { should eq(Time.utc(2012)) }
  end

  describe '#extension' do
    context 'with a content url' do
      let(:data)      {{ content_url: 'http://cl.ly/hhgttg/chapter1.txt',
                         item_type:   'text' }}
      its(:extension) { should eq('.txt') }
    end

    context 'with a content url and name' do
      let(:data)      {{ content_url: 'http://cl.ly/hhgttg/chapter1.txt',
                         name:        'chapter1.md',
                         item_type:   'text' }}
      its(:extension) { should eq('.txt') }
    end

    context 'with an extensionless content url' do
      let(:data)      {{ content_url: 'http://cl.ly/hhgttg/chapter1',
                         item_type:   'text' }}
      its(:extension) { should be_nil }
    end

    context 'pending with a name with extension' do
      let(:data)      {{ item_type:   'pending',
                         content_url: 'http://cl.ly/hhgttg',
                         name:        'chapter1.txt' }}
      its(:extension) { should eq('.txt') }
    end

    context 'pending with a name without extension' do
      let(:data)      {{ item_type:   'pending',
                         content_url: 'http://cl.ly/hhgttg',
                         name:        'chapter1' }}
      its(:extension) { should be_nil }
    end

    context 'pending without a name' do
      let(:data)      {{ item_type:   'pending',
                         content_url: 'http://cl.ly/hhgttg' }}
      its(:extension) { should be_nil }
    end
  end

  describe '#basename' do
    context 'with a name with extension' do
      let(:data)     {{ name: 'chapter1.txt' }}
      its(:basename) { should eq('chapter1') }
    end

    context 'with a name without extension' do
      let(:data)     {{ name: 'chapter1' }}
      its(:basename) { should eq('chapter1') }
    end

    context 'without a name' do
      its(:basename) { should be_nil }
    end
  end

  describe '#bookmark?' do
    context 'when a bookmark' do
      let(:data) {{ item_type: 'bookmark' }}
      it { should be_bookmark }
    end

    context 'when an image' do
      let(:data) {{ item_type: 'image' }}
      it { should_not be_bookmark }
    end
  end

  describe '#image?' do
    %w( png jpg gif ).each do |ext|
      context "when a #{ ext.upcase } file" do
        let(:data)        {{ content_url: content_url, item_type: 'image' }}
        let(:content_url) { "http://cl.ly/hhgttg/cover.#{ ext }" }
        it { should be_image }
      end
    end

    context 'an image with an upper case extension' do
      let(:data)        {{ content_url: content_url, item_type: 'image' }}
      let(:content_url) { 'http://cl.ly/hhgttg/cover.PNG' }
      it { should be_image }
    end

    context 'a TIFF file' do
      let(:data)        {{ content_url: content_url }}
      let(:content_url) { 'http://cl.ly/hhgttg/cover.tiff' }
      it { should_not be_image }
    end
  end

  describe '#plain_text?' do
    context 'a TEXT file' do
      let(:data)        {{ content_url: content_url, item_type: 'text' }}
      let(:content_url) { 'http://cl.ly/hhgttg/chapter1.text' }
      it { should be_plain_text }
    end

    context 'a TXT file' do
      let(:data)        {{ content_url: content_url, item_type: 'text' }}
      let(:content_url) { 'http://cl.ly/hhgttg/chapter1.txt' }
      it { should_not be_plain_text }
    end

    context 'an image' do
      let(:data)        {{ content_url: content_url }}
      let(:content_url) { 'http://cl.ly/hhgttg/cover.png' }
      it { should_not be_plain_text }
    end
  end

  describe '#code?' do
    let(:content) { stub(:content, code?: code) }
    let(:code)    { false }
    before do Content.stub!(:new).and_return(content) end

    it { should_not be_code }

    context 'when code' do
      let(:code) { true }
      it { should be_code }
    end
  end

  describe '#markdown?' do
    let(:content)  { stub(:content, markdown?: markdown) }
    let(:markdown) { false }
    before do Content.stub!(:new).and_return(content) end

    it { should_not be_markdown }

    context 'when markdown' do
      let(:markdown) { true }
      it { should be_markdown }
    end
  end

  describe '#text?' do
    let(:data)        {{ content_url: content_url, item_type: 'text' }}
    let(:content_url) { stub }
    let(:content)     { stub(:content, markdown?: markdown, code?: code) }
    let(:markdown)    { false }
    let(:code)        { false }
    before do Content.stub(new: content) end

    it { should_not be_text }

    context 'a plain text file' do
      let(:content_url) { 'http://cl.ly/hhgttg/chapter1.text' }
      it { should be_text }
    end

    context 'a markdown file' do
      let(:markdown) { true }
      it { should be_text }

      it 'delegates to content' do
        content.should_receive(:markdown?)
        subject.text?
      end
    end

    context 'a code file' do
      let(:code) { true }
      it { should be_text }

      it 'delegates to content' do
        content.should_receive(:code?)
        subject.text?
      end
    end
  end

  describe '#gauge_id' do
    its(:gauge_id) { should be_nil }

    context 'with a gauge id' do
      let(:data)     {{ gauge_id: gauge_id }}
      let(:gauge_id) { stub :gauge_id }
      its(:gauge_id) { should eq(gauge_id) }
    end
  end

  describe '#data' do
    let(:data) {{ name: 'The Guide' }}
    its(:data) { should eq(data) }
  end
end
