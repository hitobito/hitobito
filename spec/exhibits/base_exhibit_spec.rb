require_relative '../../app/exhibits/base_exhibit.rb'

describe BaseExhibit do

  let(:context) { double("rendering context") }
  let(:model) { double("ar model") }
  let(:subject) { BaseExhibit.new(model, context)}

  it "delegates content_tag" do
    context.should_receive(:content_tag)
    subject.content_tag
  end

  describe "#inspect calls inspect on model" do
    let(:model) { stub(inspect: 'foo') }
    its(:inspect) { should eq "Exhibit[foo]"}
  end

  describe "#kind_of?" do
    class Animal;  end
    class Dog < Animal;  end

    describe "returns true when passed base class" do
      let(:model) { Dog.new }
      specify { subject.kind_of?(Animal).should eq true } 
    end

    describe "returns false when passed super class" do
      let(:model) { Animal.new }
      specify { subject.kind_of?(Dog).should eq false } 
    end
  end
end
