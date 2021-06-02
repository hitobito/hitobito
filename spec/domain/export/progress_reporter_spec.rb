# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::ProgressReporter do
  let(:file) { Pathname.new(Dir.mktmpdir).join('subdir/file') }
  let(:values) { [] }

  subject { described_class.new(file, list.size) }

  context '1 percent steps over 1000 iterations' do
    let(:list) { (0..1000) }

    it 'has correct sequence' do
      values << subject.file.read

      list.each do |index|
        subject.report(index)
        values << subject.file.read
      end

      expect(values.uniq).to eq (0..99).to_a.collect(&:to_s)
    end
  end

  context '10 percent steps over 1000 iterations' do
    let(:list) { (1..1000) }

    it 'has correct sequence' do
      values << subject.file.read

      list.step(100) do |index|
        subject.report(index)
        values << subject.file.read
      end

      expect(values.uniq).to eq %w(0 10 20 30 40 50 60 70 80 90)
    end

  end
end
