require 'spec_helper'

describe Export::Pdf::Labels do

  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }
  let(:contactables) { [top_leader.tap{ |u| u.update(nickname: 'Funny Name') }] }
  let(:label_format) { label_formats(:standard) }
  let(:household) { false }
  let(:pdf) { Export::Pdf::Labels.new(label_format).generate(contactables, household) }

  subject { PDF::Inspector::Text.analyze(pdf) }

  context 'for nickname' do
    it 'renders pp_post if pp_post given' do
      label_format.update!(nickname: true)
      expect(subject.strings).to include('Funny Name')
    end

    it 'ignores nickname if disabled' do
      expect(subject.strings.join(' ')).not_to include('Funny Name')
    end
  end

  context 'for pp_post' do
    it 'renders pp_post if pp_post given' do
      label_format.update!(pp_post: 'CH-3030 Bern')
      expect(subject.strings).to include("CH-3030 Bern  Post CH AG")
    end

    it 'ignores pp_post if not given' do
      label_format.update!(pp_post: '  ')
      expect(subject.strings.join(' ')).not_to include("Post CH AG")
    end
  end

  context 'with households' do
    let(:household) { true }
    before do
      [top_leader, bottom_member].each do |p|
        p.update(household_key: 1)
      end
    end

    let(:contactables) { Person.where(id: [top_leader.id, bottom_member.id]) }

    it 'renders separated names' do
      expect(subject.strings).to include("Bottom Member, Top Leader")
      expect(subject.strings).to include("Greatstreet 345")
      expect(subject.strings).to include("3456 Greattown")
    end
  end

  context 'when company_name is given' do
    let(:company_name) { 'Sample Inc.' }
    let(:contactables) { [people(:top_leader).tap{ |u| u.update(company_name: company_name, company: company) }] }

    context 'when marked as a company' do
      let(:company) { true }

      it 'renders company_name' do
        expect(subject.strings).to include(company_name)
      end
    end

    context 'when not marked as a company' do
      let(:company) { false }

      it 'does not render company_name' do
        expect(subject.strings).not_to include(company_name)
      end
    end
  end
end
