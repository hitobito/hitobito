require 'spec_helper'

describe Export::Pdf::Labels do
  
  let(:contactables) { [people(:top_leader)] }
  let(:label_format) { label_formats(:standard) }
  let(:pdf) { Export::Pdf::Labels.new(label_format).generate(contactables) }

  let(:subject) { PDF::Inspector::Text.analyze(pdf) }

  context 'for nickname' do
    let(:label_format_nickname) { label_formats(:with_nickname) }
    let(:pdf_nickname) { Export::Pdf::Labels.new(label_format_nickname).generate(contactables) }

    let(:subject_nickname) { PDF::Inspector::Text.analyze(pdf_nickname) }

    it 'renders pp_post if pp_post given' do
      expect(subject_nickname.strings).to include(people(:top_leader).nickname)
    end

    it 'ignores nickname if disabled' do
      expect(subject.strings.join(' ')).not_to include(people(:top_leader).nickname)
    end
  end

  context 'for pp_post' do
    let(:label_format_pp) { label_formats(:with_pp_post) }
    let(:pdf_pp) { Export::Pdf::Labels.new(label_format_pp).generate(contactables) }

    let(:subject_pp) { PDF::Inspector::Text.analyze(pdf_pp) }

    it 'renders pp_post if pp_post given' do
      expect(subject_pp.strings).to include("#{label_format_pp.pp_post} Post CH AG")
    end

    it 'ignores pp_post if not given' do
      expect(subject.strings.join(' ')).not_to include("Post CH AG")
    end
  end
end