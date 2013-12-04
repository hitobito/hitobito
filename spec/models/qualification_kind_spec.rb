# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
describe QualificationKind do

  context 'validity is required for reactivateable' do
    subject { quali_kind }
    let(:quali_kind) { qualification_kinds(:sl) }

    before do
      quali_kind.reactivateable = 1
      quali_kind.validity = validity
    end

    context 'positive validity' do
      let(:validity) { 1 }
      it { should be_valid }
    end

    context 'negative validity' do
      let(:validity) { -1 }
      it { should have(1).error_on(:validity) }
    end

    context 'nil validity' do
      let(:validity) { nil }
      it { should have(1).error_on(:validity) }
    end
  end
end
