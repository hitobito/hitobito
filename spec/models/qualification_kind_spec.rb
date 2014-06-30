# encoding: utf-8
# == Schema Information
#
# Table name: qualification_kinds
#
#  id             :integer          not null, primary key
#  validity       :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  deleted_at     :datetime
#  reactivateable :integer
#


#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe QualificationKind do

  subject { quali_kind }
  let(:quali_kind) { qualification_kinds(:sl) }

  context 'validity is required for reactivateable' do

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

  it 'remembers label when destroying entry' do
    subject.destroy
    subject.to_s.should == 'Super Lead'
  end

  it 'does not destroy translations on soft destroy' do
    Fabricate(:qualification, qualification_kind: subject)
    expect { subject.destroy }.not_to change { QualificationKind::Translation.count }
  end

  it 'does destroy translations on hard destroy' do
    expect { subject.destroy! }.to change { QualificationKind::Translation.count }.by(-1)
  end

end
