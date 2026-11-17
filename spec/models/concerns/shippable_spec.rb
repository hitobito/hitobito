# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Shippable do
  subject(:letter) { Message::Letter.new(shipping_method: "priority", pp_post: "CH-3030 Bern") }

  context "with all shippable attributes" do
    it "uses the stored values" do
      expect(letter.effective_shipping_method).to eq "priority"
      expect(letter.effective_pp_post).to eq "CH-3030 Bern"
      expect(letter).to be_shipping_info
    end

    it "has shipping info for pp_post only" do
      letter.shipping_method = "own"

      expect(letter).to be_shipping_info
    end

    it "has no shipping info for own shipping without pp_post" do
      letter.shipping_method = "own"
      letter.pp_post = " "

      expect(letter).not_to be_shipping_info
    end
  end

  [nil, ""].each do |blank|
    it "rejects #{blank.inspect} as shipping method" do
      letter.shipping_method = blank

      expect(letter).not_to be_valid
      expect(letter.errors.attribute_names).to include :shipping_method
    end
  end

  context "without shippable attributes" do
    before { allow(Message::Letter).to receive(:shippable_attributes).and_return([]) }

    it "ignores the stored values" do
      expect(letter.effective_shipping_method).to eq "own"
      expect(letter.effective_pp_post).to be_nil
      expect(letter).not_to be_shipping_info
    end
  end
end
