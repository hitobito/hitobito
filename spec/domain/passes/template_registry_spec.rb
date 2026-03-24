#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Passes::TemplateRegistry do
  let(:default_args) do
    {
      pdf_class: Class.new,
      pass_view_partial: "default",
      wallet_data_provider: Passes::WalletDataProvider
    }
  end

  around do |example|
    original_value = described_class.instance_variable_get(:@registry)
    described_class.reset!
    example.run
  ensure
    described_class.instance_variable_set(:@registry, original_value)
  end

  describe ".register and .fetch" do
    it "registers and fetches a template bundle" do
      foo_pdf_class = Class.new

      described_class.register("foo",
        pdf_class: foo_pdf_class,
        pass_view_partial: "foo",
        wallet_data_provider: Passes::WalletDataProvider)

      template = described_class.fetch("foo")

      expect(template).to be_a(described_class::Template)
      expect(template.pdf_class).to eq(foo_pdf_class)
      expect(template.pass_view_partial).to eq("foo")
      expect(template.wallet_data_provider).to eq(Passes::WalletDataProvider)
    end
  end

  describe ".fetch" do
    it "raises KeyError for unknown keys" do
      expect { described_class.fetch("unknown") }.to raise_error(KeyError)
    end
  end

  describe ".available_keys" do
    it "returns all registered keys" do
      described_class.register("alpha", **default_args)
      described_class.register("beta", **default_args)

      expect(described_class.available_keys).to contain_exactly("alpha", "beta")
    end
  end

  describe ".reset!" do
    it "clears the registry" do
      described_class.register("alpha", **default_args)

      described_class.reset!

      expect(described_class.available_keys).to eq([])
    end
  end
end
