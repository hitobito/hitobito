# frozen_string_literal: true

#  Copyright (c) 2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::ProgressReporter do
  let(:file) { Pathname.new(Dir.mktmpdir).join("subdir/file") }
  let(:values) { [] }

  subject { described_class.new(file, list.size) }

  context "5 percent steps over 1000 iterations"  do
    let(:list) { (0..1000) }

    it "has correct sequence" do
      list.each do |index|
        subject.report(index)
        values << subject.file.read if subject.file.exist?
      end
      expect(values.uniq).to eq (0..99).to_a.collect(&:to_s)
    end
  end
end
