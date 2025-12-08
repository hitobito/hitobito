# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Contactable do
  shared_examples "fixing common autocomplete issues" do |column|
    let(:street) { "Main Street" }
    let(:housenumber) { "23a" }
    let(:zip_code) { 1234 }
    let(:town) { "Jamestown" }

    subject(:model) { described_class.new(street:, housenumber:, zip_code:, town:) }

    relevant_attrs = [:street, :housenumber, :zip_code, :town]
    relevant_attrs.each do |attr|
      it "maintains valid #{column} value" do
        model.send(:"#{column}=", "3000")
        model.valid?
        expect(model.send(column)).to eq "3000"
      end

      it "clears #{column} if it equals #{attr} value" do
        model.send(:"#{column}=", send(attr))
        model.valid?
        expect(model.send(column)).to be_nil
      end

      it "clears #{column} if it equals 'street housenumber' value" do
        model.send(:"#{column}=", "#{street} #{housenumber}")
        model.valid?
        expect(model.send(column)).to be_nil
      end

      it "does not clear #{column} if it only contains #{attr} value" do
        model.send(:"#{column}=", "pre #{send(attr)} post")
        model.valid?
        expect(model.send(column)).to eq "pre #{send(attr)} post"
      end
    end
  end

  describe Person do
    it_behaves_like "fixing common autocomplete issues", :postbox
    it_behaves_like "fixing common autocomplete issues", :address_care_of
  end

  describe Group do
    it_behaves_like "fixing common autocomplete issues", :postbox
    it_behaves_like "fixing common autocomplete issues", :address_care_of
  end
end
