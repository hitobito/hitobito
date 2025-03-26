require "spec_helper"

describe Patches do
  it "generates expected output" do
    patches = Patches::Runner.new
    binding.pry
    expect(patches.added_methods.size).to eq 20
  end
end
