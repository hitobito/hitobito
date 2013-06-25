require 'spec_helper'
describe Event::Answer do
  let(:question) { event_questions(:top_ov) }
  let(:choices) { question.choices.split(',') }

  context "answer= for array values (checkboxes)" do
    subject { question.reload.answers.build }

    before do
      question.update_attribute(:multiple_choices, true)
      subject.answer = answer_param
    end


    context "valid array values (position + 1)" do
      let(:answer_param) { ["1", "2"] }
      its(:answer) { should eq "GA, Halbtax" }
      it { should have(0).errors_on(:answer) }
    end

    context "values outside of array size" do
      let(:answer_param) { ["4", "5"] }
      its(:answer) { should be_nil }
    end

    context "resetting values" do
      subject { question.reload.answers.build(answer: "GA, Halbtax") }

      let(:answer_param) { ["0"] }
      its(:answer) { should be_nil }
    end
  end

end
