# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe IbanValidator do
  class DummyModel # rubocop:disable Lint/ConstantDefinitionInBlock
    include ActiveModel::Model
    attr_accessor :iban

    validates :iban, iban: true
  end

  let(:model) { DummyModel.new }

  shared_examples "iban validator" do |valid:, invalid:|
    valid.each do |iban|
      it "#{iban} to be valid" do
        model.iban = iban
        expect(model).to be_valid
        expect(model.errors).to be_empty
      end
    end
    invalid.each do |iban|
      it "#{iban} to be invalid" do
        model.iban = iban
        model.validate
        expect(model.errors[:iban]).to include(I18n.t("errors.messages.invalid_iban"))
      end
    end
  end

  describe "swiss iban" do
    it_behaves_like "iban validator",
      valid: ["CH9300762011623852957", "CH5604835012345678009", "CH9300762011623852957"],
      invalid: ["CH930076201162", "12345678009", "ch5604835012345678009", "CH3709000010304465560", "CH3509000000304445560"]
  end

  describe "german iban" do
    it_behaves_like "iban validator",
      valid: ["DE89370400440532013000", "DE12500105170648489890", "DE75512108001245126199"],
      invalid: ["DE893704004405", "105170648489890", "de12500105170648489890", "DE75512108001243126198", "DE73512108001245126199"]
  end

  describe "austrian iban" do
    it_behaves_like "iban validator",
      valid: ["AT611904300234573201", "AT483200000012345864", "AT611904300234573201"],
      invalid: ["AT6119043002", "00012345864", "at483200000012345864", "AT611200000412345718", "AT621200000012345708"]
  end

  describe "icelandic iban" do
    it_behaves_like "iban validator",
      valid: ["IS310159463554744441206319", "IS320159048016165654296269", "IS350159797360851167069750"],
      invalid: ["IS1401592600", "5606304016473916", "is320159048016165654296269", "IS060129150212345674904318", "IS160129150212345678904317"]
  end
end
