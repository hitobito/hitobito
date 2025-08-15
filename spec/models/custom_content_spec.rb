#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: custom_contents
#
#  id                    :integer          not null, primary key
#  key                   :string           not null
#  label                 :string           not null
#  placeholders_optional :string
#  placeholders_required :string
#  subject               :string
#

require "spec_helper"

describe CustomContent do
  subject { custom_contents(:login) }

  context "scopes" do
    let!(:layer_custom_content) { Fabricate(:custom_content, context: Group.root) }
    let!(:invoice_config_custom_content) { Fabricate(:custom_content, context: invoice_configs(:top_layer)) }

    it "does not return custom contents from layer groups per default" do
      expect(CustomContent.all).to include(subject)
      expect(CustomContent.all).not_to include(layer_custom_content)
      expect(CustomContent.all).not_to include(invoice_config_custom_content)
    end

    it "in_context only returns custom contents from group context" do
      expect(CustomContent.in_context(Group.root)).not_to include(subject)
      expect(CustomContent.in_context(Group.root)).to include(layer_custom_content)
      expect(CustomContent.in_context(Group.root)).not_to include(invoice_config_custom_content)
    end

    it "in_context only returns custom contents from invoice config context" do
      expect(CustomContent.in_context(invoice_configs(:top_layer))).not_to include(subject)
      expect(CustomContent.in_context(invoice_configs(:top_layer))).not_to include(layer_custom_content)
      expect(CustomContent.in_context(invoice_configs(:top_layer))).to include(invoice_config_custom_content)
    end
  end

  context ".list" do
    it "contains one entry per main item" do
      expect(CustomContent.list.size).to eq(CustomContent.count)
    end
  end

  context "lists" do
    it "creates empty list for nil" do
      expect(custom_contents(:notes).placeholders_required_list).to eq([])
    end

    it "creates list with one element" do
      expect(subject.placeholders_required_list).to eq(["login-url"])
    end

    it "creates list with several elements" do
      subject.placeholders_required = "login-url, foo ,bar"
      expect(subject.placeholders_required_list).to eq(%w[login-url foo bar])
    end

    it "creates list with several elements from main custom content" do
      subject.update!(placeholders_required: nil)
      context_custom_content = Fabricate(:custom_content, context: Group.root, key: subject.key)
      subject.update!(placeholders_required: "login-url, foo ,bar", body: "{login-url}{foo}{bar}")
      expect(context_custom_content.placeholders_required_list).to eq(%w[login-url foo bar])
    end
  end

  describe ".get" do
    let(:invoice_config) { invoice_configs(:top_layer) }
    let(:key) { :content_invoice_notification }

    it "raises when nothing is found for key" do
      expect { CustomContent.get(:missing) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises when nothing is found for key and context" do
      expect { CustomContent.get(:missing, context: invoice_config) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "returns global custom content" do
      expect(CustomContent.get(key)).to eq custom_contents(:content_invoice_notification)
    end

    it "returns global custom content for context if nothing specific is defined" do
      expect(CustomContent.get(key, context: invoice_config)).to eq custom_contents(:content_invoice_notification)
    end

    it "returns specific custom content for context if exists" do
      specific = Fabricate(:custom_content, key: key, context: invoice_config,
        body: "{invoice-items}, {invoice-total}, {payment-information}")
      expect(CustomContent.get(key, context: invoice_config)).to eq specific
    end
  end

  context "validations" do
    it "succeeds without defined placeholders" do
      cc = custom_contents(:notes)
      expect(cc).to be_valid
    end

    it "succeeds with only optional placeholders" do
      subject.placeholders_required = nil
      is_expected.to be_valid
    end

    it "fail if one required placeholder is missing" do
      subject.placeholders_required = "login-url, sender"
      is_expected.not_to be_valid
    end

    it "succeeds if all required placeholders are used" do
      is_expected.to be_valid
    end

    it "succeeds if placeholder is used in subject" do
      subject.placeholders_required = "login-url, sender"
      subject.subject = "Mail from {sender}"

      is_expected.to be_valid
    end

    it "fails in context when required placeholder from main custom content is missing" do
      context_custom_content = Fabricate(:custom_content, context: Group.root, key: subject.key, body: "{login-url}")
      context_custom_content.body = ""
      expect(context_custom_content).not_to be_valid
    end
  end

  context "#body_with_values" do
    it "replaces all placeholders" do
      subject.body = "Hello {recipient-name}, here is your site to login: {login-url}. Goodbye {recipient-name}"
      output = subject.body_with_values("recipient-name" => "Fred", "login-url" => "example.com/login")
      expect(output).to match("Hello Fred, here is your site to login: example.com/login. Goodbye Fred")
    end

    it "handles contents without placeholders" do
      expect(custom_contents(:notes).body_with_values).to match("Bla bla bla bla")
    end

    it "raises an error if placeholder is missing" do
      expect { subject.body_with_values("login-url" => "example.com/login") }.to raise_error(KeyError)
    end

    it "raises an error if non-defined placeholder is given" do
      expect { custom_contents(:notes).body_with_values("foo" => "bar") }.to raise_error(ArgumentError)
    end

    it "does not care about unused placeholders" do
      subject.body = "Hello You, here is your site to login: {login-url}"
      output = subject.body_with_values("recipient-name" => "Fred", "login-url" => "example.com/login")
      expect(output).to match("Hello You, here is your site to login: example.com/login")
    end

    it "use fallback locale if body in request locale is empty" do
      output = I18n.with_locale(:it) do
        subject.body_with_values("recipient-name" => "Fred", "login-url" => "example.com/login")
      end
      expect(output).to match("Salut Fred, voici ta site login: example.com/login")
    end

    it "escapes html entities" do
      subject.body = "Hello {recipient-name}"
      output = subject.body_with_values("recipient-name" => "<a>World</a>")
      expect(output).to match("Hello &lt;a&gt;World&lt;/a&gt;")
    end
  end

  context "#subject_with_values" do
    it "replaces all placeholders" do
      subject.subject = "New Login for {recipient-name} at {login-url}"
      output = subject.subject_with_values("recipient-name" => "Fred", "login-url" => "example.com/login")
      expect(output).to eq("New Login for Fred at example.com/login")
    end

    it "handles contents without placeholders" do
      subject.subject = "Hi There"
      output = subject.subject_with_values
      expect(output).to eq("Hi There")
    end

    it "raises an error if placeholder is missing" do
      subject.subject = "Your new Login at {login-url}"
      expect { subject.subject_with_values("recipient-name" => "Fred") }.to raise_error(KeyError)
    end

    it "raises an error if non-defined placeholder is given" do
      subject.subject = "Your new Login"
      expect { subject.subject_with_values("foo" => "bar") }.to raise_error(ArgumentError)
    end

    it "does not care about unused placeholders" do
      subject.subject = "Your new Login at {login-url}"
      output = subject.subject_with_values("recipient-name" => "Fred", "login-url" => "example.com/login")
      expect(output).to eq("Your new Login at example.com/login")
    end

    it "escapes html entities" do
      subject.subject = "Hello {recipient-name}"
      output = subject.subject_with_values("recipient-name" => "<a>World</a>")
      expect(output).to eq("Hello &lt;a&gt;World&lt;/a&gt;")
    end
  end
end
