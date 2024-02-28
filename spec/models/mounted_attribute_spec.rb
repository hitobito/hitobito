# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe MountedAttribute do
  def set_config(attr_type, default: nil)
    allow(subject).to receive(:config).and_return(
      MountedAttributes::Config.new('target_class', 'attr_name', attr_type, default: default)
    )
  end

  context 'setter' do
    def expect_assigned(input, expected)
      subject.value = input
      expect(subject.read_attribute(:value)).to eq expected
    end

    context 'for integer type' do
      before { set_config(:integer) }

      it 'sets value' do
        expect_assigned(42, 42)
      end

      it 'casts string to integer' do
        expect_assigned('42', 42)
      end

      it 'casts empty string to nil' do
        expect_assigned('', nil)
      end

      it 'sets nil' do
        expect_assigned(nil, nil)
      end

      it 'sets default' do
        set_config(:integer, default: 42)
        expect_assigned(nil, 42)
      end
    end

    context 'for string type' do
      before { set_config(:string) }

      it 'sets value' do
        expect_assigned('foo', 'foo')
      end

      it 'casts integer to string' do
        expect_assigned(42, '42')
      end

      it 'sets nil' do
        expect_assigned(nil, nil)
      end

      it 'sets default' do
        set_config(:string, default: 'foo')
        expect_assigned(nil, 'foo')
      end
    end

    context 'for boolean type' do
      before { set_config(:boolean) }

      it 'sets value' do
        expect_assigned(true, true)
      end

      it 'casts string to boolean' do
        expect_assigned('true', true)
      end

      it 'casts "0" to false' do
        expect_assigned('0', false)
      end

      it 'casts "1" to true' do
        expect_assigned('1', true)
      end

      it 'casts 0 to false' do
        expect_assigned(0, false)
      end

      it 'casts 1 to true' do
        expect_assigned(1, true)
      end

      it 'casts empty string to nil' do
        expect_assigned('', nil)
      end

      it 'sets nil' do
        expect_assigned(nil, nil)
      end

      it 'sets default' do
        set_config(:boolean, default: true)
        expect_assigned(nil, true)
      end
    end
  end

  context 'getter' do
    def expect_read(assigned, expected)
      subject.write_attribute(:value, assigned)
      expect(subject.value).to eq expected
    end

    context 'for integer type' do
      before { set_config(:integer) }

      it 'reads value' do
        expect_read(42, 42)
      end

      it 'does not cast string' do
        expect_read('42', '42')
      end

      it 'reads nil' do
        expect_read(nil, nil)
      end

      it 'gets default' do
        set_config(:integer, default: 42)
        expect_read(nil, 42)
      end
    end

    context 'for string type' do
      before { set_config(:string) }

      it 'reads value' do
        expect_read('foo', 'foo')
      end

      it 'reads nil' do
        expect_read(nil, nil)
      end

      it 'gets default' do
        set_config(:string, default: 'foo')
        expect_read(nil, 'foo')
      end
    end

    context 'for boolean type' do
      before { set_config(:boolean) }

      it 'reads value' do
        expect_read(true, true)
      end

      it 'doest not cast string to boolean' do
        expect_read('true', 'true')
      end

      it 'reads nil' do
        expect_read(nil, nil)
      end

      it 'gets default' do
        set_config(:boolean, default: true)
        expect_read(nil, true)
      end
    end
  end

end
