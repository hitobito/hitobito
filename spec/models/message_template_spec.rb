require "rails_helper"

describe MessageTemplate, type: :model do
  let(:message_template) { message_templates(:top_layer_one) }

  describe "#valid?" do
    it "validates presence of title" do
      message_template = described_class.new
      expect(message_template).not_to be_valid
      message_template.title = "New Title"
      expect(message_template).to be_valid
    end
  end

  describe "#option_for_select" do
    it "returns usable array" do
      expect(message_template.option_for_select).to eq([message_template.title, message_template.id,
        data: {title: message_template.title, description: message_template.body}])
    end
  end
end
