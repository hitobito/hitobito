# frozen_string_literal: true
#
# Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

require 'spec_helper'

describe Roles::Title do
  let(:group) { groups(:bottom_layer_one) }
  let(:date) { Date.new(2023, 11, 15) }

  def title(attrs = {})
    role = Fabricate.build(Group::BottomLayer::Leader.sti_name, attrs.merge(group: group))
    described_class.new(role)
  end

  describe '#parts' do
    it 'is empty when no relevant fields are present' do
      expect(title.parts).to be_empty
    end

    it 'includes label' do
      expect(title(label: 'test').parts).to eq ['(test)']
    end

    it 'includes label and convert_on' do
      expect(title(label: 'test', convert_on: date).parts).to eq ['(test)', '(ab 15.11.2023)']
    end

    it 'includes label and convert_on and delete_on by default' do
      expect(title(label: 'test', convert_on: date, delete_on: date).parts).to eq [
        '(test)',
        '(ab 15.11.2023)',
        '(bis 15.11.2023)'
      ]
    end

    it 'may control which parts are included' do
      expect(title(label: 'test', convert_on: date, delete_on: date).parts(:label, :delete_on)).to eq [
        '(test)',
        '(bis 15.11.2023)'
      ]
    end
  end
end
