require 'delegate'
require 'metriks'
require 'yajl'

class DropPresenter < SimpleDelegator
  def initialize(drop, template)
    @template = template
    super drop
  end

  def render_html
    render_timer do
      if bookmark?
        @template.redirect remote_url, 301
      else
        @template.erb template_name, layout: layout_name,
                                     locals: { drop: self, body_id: body_id }
      end
    end
  end

  def render_json
    render_timer do
      Yajl::Encoder.encode data
    end
  end

  def render_content
    @template.redirect_to_content slug, remote_url, updated_at
  end

private

  def layout_name
    "#{ (beta? || pending?) ? 'new_' : '' }layout".to_sym
  end

  def template_name
    if pending?
      :new_waiting
    elsif image?
      if beta?
        :new_image
      else
        :image
      end
    elsif video?
      :video
    elsif text?
      if beta?
        :new_markdown
      else
        :text
      end
    else
      if beta?
        :new_download
      else
        :other
      end
    end
  end

  def body_id
    if pending?
      'waiting'
    elsif image?
      'image'
    elsif text?
      'text'
    else
      'other'
    end
  end

  def render_timer(&block)
    Metriks.timer("drop.render.#{ body_id }").time(&block)
  end
end
