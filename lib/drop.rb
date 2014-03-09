require 'base64'
require 'content'
require 'forwardable'

class Drop
  extend Forwardable

  attr_accessor :slug, :data

  def initialize(slug, data)
    @slug    = slug
    @data    = data
    @content = Content.new remote_url
  end

  def_delegators :@content, :content, :markdown?, :code?

  def subscribed?()   @data[:subscribed]    end
  def item_type()     @data[:item_type]     end
  def share_url()     @data[:url]           end
  def thumbnail_url() @data[:thumbnail_url] end
  def content_url()   @data[:content_url]   end
  def download_url()  @data[:download_url]  end
  def name()          @data[:name]          end
  def gauge_id()      @data[:gauge_id]      end
  def bookmark?()     @data[:item_type] == 'bookmark' end
  def pending?()      @data[:item_type] == 'pending'  end
  def updated_at()    Time.parse @data[:updated_at]   end
  def remote_url()    @data[:remote_url] || redirect_url end

  def redirect_url
    url = @data[:redirect_url]
    return url if url.nil? || includes_protocol?(url)
    "http://#{url}"
  end

  def beta?
    source = @data.fetch :source, nil
    source and (source.include?('CloudApp/2.0') or
                source.include?('Cloud/2.0') or
                source.include?('cloudapp-gem/'))
  end

  def image?
    %w( .bmp
        .gif
        .ico
        .jp2
        .jpe
        .jpeg
        .jpf
        .jpg
        .jpg2
        .jpgm
        .png ).include? extension
  end

  def video?
    %w( .mov
        .mp4
        .m4v ).include? extension
  end

  def plain_text?
    extension == '.text'
  end

  def text?
    plain_text? || markdown? || code?
  end

  def basename
    basename = File.basename(name.to_s, File.extname(name.to_s))
    basename.empty? ? nil : basename
  end

  def extension
    extname = File.extname(file_name).downcase
    extname.empty? ? nil : extname
  end

private

  def file_name
    file_name = pending? ? name : content_url
    file_name.to_s
  end

  # Regex borrowed from Sinatra
  # https://github.com/sinatra/sinatra/blob/da3282f/lib/sinatra/base.rb#L265
  def includes_protocol?(url)
    url =~ /\A[A-z][A-z0-9\+\.\-]*:/
  end
end
