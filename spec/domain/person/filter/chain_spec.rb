require 'spec_helper'

describe Person::Filter::Chain do

  context 'initialize' do

    it 'only build present filters' do
      chain = Person::Filter::Chain.new(role: { role_type_ids: '' }, qualification: { })
      expect(chain).to be_blank
    end

  end

  context 'to_a' do
    it 'includes all present filters' do
      chain = Person::Filter::Chain.new(role: { role_type_ids: '2-6-9' },
                                        qualification: { qualification_kind_ids: [] })
      expect(chain.to_hash).to eq({ role: { role_type_ids: '2-6-9' } }.deep_stringify_keys)
    end
  end

  context 'dump' do
    it 'serializes all present filters' do
      chain = Person::Filter::Chain.new(role: { role_type_ids: '2-6-9' },
                                        qualification: { qualification_kind_ids: ['14'] })
      yaml = Person::Filter::Chain.dump(chain)
      roundtrip = Person::Filter::Chain.load(yaml)
      expect(roundtrip.to_hash).to eq({ role: { role_type_ids: '2-6-9' },
                                        qualification: { qualification_kind_ids: '14' } }.deep_stringify_keys)
    end
  end

end
