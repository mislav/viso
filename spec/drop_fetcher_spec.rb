require 'support/vcr'
require 'webmock/rspec'
require 'drop_fetcher'

describe DropFetcher do
  let(:drop_fetcher) {
    described_class.new(:api_host => 'api.cld.me')
  }

  describe '.fetch' do
    it 'returns a drop' do
      EM.synchrony do
        VCR.use_cassette 'bookmark' do
          drop = drop_fetcher.fetch 'hhgttg'
          EM.stop

          drop.should be_a(Drop)
        end
      end
    end

    it 'symbolizes keys' do
      Drop.should_receive(:new).with('hhgttg', hash_including(:content_url))

      EM.synchrony do
        VCR.use_cassette 'bookmark' do
          drop_fetcher.fetch 'hhgttg'
          EM.stop
        end
      end
    end

    it 'raises a DropNotFound error' do
      EM.synchrony do
        VCR.use_cassette 'nonexistent' do
          lambda { drop_fetcher.fetch 'hhgttg' }.
            should raise_error(DropFetcher::NotFound)

          EM.stop
        end
      end
    end
  end

  describe '.record_view' do
    it 'records the view' do
      EM.synchrony do
        stub_request(:post, 'http://api.cld.me/hhgttg/view').
          to_return(:status => [201, 'Created'])

        drop_fetcher.record_view 'hhgttg'
        EM.stop

        assert_requested :post, 'http://api.cld.me/hhgttg/view'
      end
    end
  end
end
