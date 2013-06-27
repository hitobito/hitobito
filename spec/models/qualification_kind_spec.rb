require 'spec_helper'
describe QualificationKind do

  context "validity is required for reactivateable" do
    subject { quali_kind }
    let(:quali_kind) { qualification_kinds(:sl) }

    before do
      quali_kind.reactivateable = 1
      quali_kind.validity = validity
    end

    context "positive validity" do
      let(:validity) { 1 }
      it { should be_valid }
    end

    context "negative validity" do
      let(:validity) { -1 }
      it { should have(1).error_on(:validity) }
    end

    context "nil validity" do
      let(:validity) { nil }
      it { should have(1).error_on(:validity) }
    end
  end
end
