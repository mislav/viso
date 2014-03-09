require 'drop_presenter'

describe DropPresenter do
  describe '#render_html' do
    let(:drop) { double(:drop, slug:       'hhgttg',
                               beta?:      beta,
                               bookmark?:  bookmark,
                               image?:     image,
                               text?:      text,
                               markdown?:  markdown,
                               pending?:   pending,
                               remote_url: 'http://remote.url',
                               updated_at: updated_at) }
    let(:beta)       { false }
    let(:bookmark)   { false }
    let(:image)      { false }
    let(:text)       { false }
    let(:markdown)   { false }
    let(:pending)    { false }
    let(:updated_at) { double(:updated_at) }
    subject { DropPresenter.new drop, template }

    describe 'a bookmark drop' do
      let(:bookmark) { true }
      let(:template) { double(:template, redirect: nil) }

      it 'redirects to the bookmarked url' do
        template.should_receive(:redirect).with('http://remote.url', 301)
        subject.render_html
      end

      context 'shared with a beta mac app' do
        let(:beta) { true }
        it 'redirects to the api' do
          template.should_receive(:redirect).with('http://remote.url', 301)
          subject.render_html
        end
      end
    end

    describe 'a pending drop' do
      let(:image)    { true }
      let(:text)     { true }
      let(:markdown) { true }
      let(:pending)  { true }
      let(:content)  { 'content' }
      let(:template) { double(:template, erb: content) }

      it 'renders the erb template with new layout' do
        template.
          should_receive(:erb).
          with(:new_waiting, layout: :new_layout, locals: { drop: drop, body_id: 'waiting' })

        subject.render_html
      end

      context 'shared with a beta mac app' do
        let(:beta) { true }

        it 'renders the erb template with new layout' do
          template.
            should_receive(:erb).
            with(:new_waiting, layout: :new_layout, locals: { drop: drop, body_id: 'waiting' })

          subject.render_html
        end
      end
    end

    describe 'an image drop' do
      let(:image)    { true }
      let(:content)  { 'content' }
      let(:template) { double(:template, erb: content) }

      it 'returns template content' do
        subject.render_html.should == content
      end

      it 'renders the erb template' do
        template.
          should_receive(:erb).
          with(:image, layout: :layout, locals: { drop: drop, body_id: 'image' })

        subject.render_html
      end

      context 'shared with a beta mac app' do
        let(:beta) { true }

        it 'renders the new erb template with new layout' do
          template.
            should_receive(:erb).
            with(:new_image, layout: :new_layout, locals: { drop: drop, body_id: 'image' })

          subject.render_html
        end
      end
    end

    describe 'a text drop' do
      let(:text)     { true }
      let(:content)  { 'content' }
      let(:template) { double(:template, erb: content) }

      it 'returns template content' do
        subject.render_html.should == content
      end

      it 'renders the erb template' do
        template.
          should_receive(:erb).
          with(:text, layout: :layout, locals: { drop: drop, body_id: 'text' })

        subject.render_html
      end

      context 'shared with a beta mac app' do
        let(:beta) { true }

        it 'renders the erb template' do
          template.
            should_receive(:erb).
            with(:new_markdown, layout: :new_layout, locals: { drop: drop, body_id: 'text' })

          subject.render_html
        end
      end
    end

    describe 'a markdown drop' do
      let(:text)     { true }
      let(:markdown) { true }
      let(:content)  { 'content' }
      let(:template) { double(:template, erb: content) }

      it 'returns template content' do
        subject.render_html.should == content
      end

      it 'renders the erb template' do
        template.
          should_receive(:erb).
          with(:text, layout: :layout, locals: { drop: drop, body_id: 'text' })

        subject.render_html
      end

      context 'shared with a beta mac app' do
        let(:beta) { true }

        it 'renders the new erb template with new layout' do
          template.
            should_receive(:erb).
            with(:new_markdown, layout: :new_layout, locals: { drop: drop, body_id: 'text' })

          subject.render_html
        end
      end
    end

    describe 'an unknown drop' do
      let(:content)  { 'content' }
      let(:template) { double(:template, erb: content) }

      it 'returns template content' do
        subject.render_html.should == content
      end

      it 'renders the erb template' do
        template.
          should_receive(:erb).
          with(:other, layout: :layout, locals: { drop: drop, body_id: 'other' })

        subject.render_html
      end

      context 'shared with a beta mac app' do
        let(:beta) { true }

        it 'renders the new erb template with new layout' do
          template.
            should_receive(:erb).
            with(:new_download, layout: :new_layout, locals: { drop: drop, body_id: 'other' })

          subject.render_html
        end
      end
    end
  end

  describe '#render_json' do
    let(:template) { double(:template) }
    let(:drop)     { double(:drop, pending?: false,
                                   image?:   false,
                                   text?:    false,
                                   data:     { key: 'value' }) }
    subject { DropPresenter.new drop, template }

    it 'returns the drop as json' do
      subject.render_json.should == '{"key":"value"}'
    end
  end

  describe '#render_content' do
    let(:template)   { double(:template, redirect_to_content: nil) }
    let(:drop)       { double(:drop, slug:       'hhgttg',
                                     remote_url: 'http://remote.url',
                                     updated_at: updated_at) }
    let(:updated_at) { double(:updated_at) }
    subject { DropPresenter.new drop, template }

    it 'redirects to the content' do
      template.should_receive(:redirect_to_content).
        with('hhgttg', 'http://remote.url', updated_at)
      subject.render_content
    end
  end
end
