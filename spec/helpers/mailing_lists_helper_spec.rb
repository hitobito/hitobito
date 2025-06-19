#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe MailingListsHelper do
  include UtilityHelper
  include FormatHelper
  include LayoutHelper

  let(:entry) { mailing_lists(:leaders) }
  let(:current_user) { people(:top_leader) }

  describe "#format_mailing_list_name" do
    let(:dom) { Capybara::Node::Simple.new(format_mailing_list_name(entry)) }

    it "renders name with link to messages path if user can update" do
      expect(self).to receive(:can?).with(:update, entry).and_return(true)
      expect(dom).to have_link "Leaders", href: group_mailing_list_messages_path(entry.group, entry)
    end

    it "renders name only if user cannot update" do
      expect(self).to receive(:can?).with(:update, entry).and_return(false)
      expect(dom).not_to have_link "Leaders"
      expect(dom).to have_text "Leaders"
    end
  end

  describe "#button_toggle_subscription" do
    it "with subscribed user shows 'Anmelden'" do
      expect(self).to receive_messages(can?: true)
      sub = entry.subscriptions.new
      sub.subscriber = current_user
      sub.save!

      @group = entry.group
      expect(button_toggle_subscription).to match(/Abmelden/)
    end

    it "with not subscribed user shows 'Abmelden'" do
      expect(self).to receive_messages(can?: true)
      @group = entry.group
      expect(button_toggle_subscription).to match(/Anmelden/)
    end
  end

  describe "#generate_mailing_list_filter_info_items" do
    let(:list) do
      double("List", filter_chain: {
        attributes: Person::Filter::Attributes.new("attributes", filters)
      })
    end

    describe "with text attribute set" do
      let(:filters) do
        {
          timestamp: {
            key: "company_name",
            constraint: "equal",
            value: "Puzzle ITC"
          }
        }
      end

      it "renders equal constraint" do
        html = helper.mailing_list_attributes_filter_info_items(list)
        expect(html).to include("<li>Firmenname ist genau Puzzle ITC</li>")
      end

      it "renders equal constraint" do
        filters[:timestamp][:constraint] = "match"
        html = helper.mailing_list_attributes_filter_info_items(list)
        expect(html).to include("<li>Firmenname enthält Puzzle ITC</li>")
      end

      it "renders equal constraint" do
        filters[:timestamp][:constraint] = "not_match"
        html = helper.mailing_list_attributes_filter_info_items(list)
        expect(html).to include("<li>Firmenname enthält nicht Puzzle ITC</li>")
      end
    end

    describe "with numerical attribute set" do
      let(:filters) do
        {
          timestamp: {
            key: "years",
            constraint: "equal",
            value: "56"
          }
        }
      end

      it "renders equal constraint" do
        html = helper.mailing_list_attributes_filter_info_items(list)
        expect(html).to include("<li>Alter ist genau 56</li>")
      end

      it "renders equal constraint" do
        filters[:timestamp][:constraint] = "greater"
        html = helper.mailing_list_attributes_filter_info_items(list)
        expect(html).to include("<li>Alter grösser als 56</li>")
      end

      it "renders equal constraint" do
        filters[:timestamp][:constraint] = "smaller"
        html = helper.mailing_list_attributes_filter_info_items(list)
        expect(html).to include("<li>Alter kleiner als 56</li>")
      end
    end

    describe "with language attribute set" do
      let(:filters) do
        {
          timestamp: {
            key: "language",
            constraint: "equal",
            value: ["de", "it", "fr"]
          }
        }
      end

      it "renders multiple language options" do
        html = helper.mailing_list_attributes_filter_info_items(list)
        expect(html).to include("<li>Sprache ist genau Deutsch, Französisch oder Italienisch</li>")
      end

      it "renders two language options" do
        filters[:timestamp][:value] = ["de", "it"]
        html = helper.mailing_list_attributes_filter_info_items(list)
        expect(html).to include("<li>Sprache ist genau Deutsch oder Italienisch</li>")
      end

      it "renders one language options" do
        filters[:timestamp][:value] = ["de"]
        html = helper.mailing_list_attributes_filter_info_items(list)
        expect(html).to include("<li>Sprache ist genau Deutsch</li>")
      end
    end

    describe "with country attribute set" do
      let(:filters) do
        {
          timestamp: {
            key: "country",
            constraint: "equal",
            value: [" ", "IT", "AT", "CH", "DE"]
          }
        }
      end

      it "renders multiple country options" do
        html = helper.mailing_list_attributes_filter_info_items(list)
        expect(html).to include("<li>Land ist genau Deutschland, Italien, Schweiz oder Österreich</li>")
      end

      it "renders two country options" do
        filters[:timestamp][:value] = ["DE", "CH"]
        html = helper.mailing_list_attributes_filter_info_items(list)
        expect(html).to include("<li>Land ist genau Deutschland oder Schweiz</li>")
      end

      it "renders one country option" do
        filters[:timestamp][:value] = ["DE"]
        html = helper.mailing_list_attributes_filter_info_items(list)
        expect(html).to include("<li>Land ist genau Deutschland</li>")
      end
    end

    describe "with gender attribute set" do
      let(:filters) do
        {
          timestamp: {
            key: "gender",
            constraint: "equal",
            value: ["m", "w", ""]
          }
        }
      end

      it "renders all gender options" do
        html = helper.mailing_list_attributes_filter_info_items(list)
        # expect(html).to include('<li>Alter ist genau 56</li>')
        # expect(html).to include('<li>Land ist genau Italien, Schweiz oder Österreich</li>')
        expect(html).to include("<li>Geschlecht ist genau männlich, unbekannt oder weiblich</li>")
      end

      it "renders two gender options" do
        filters[:timestamp][:value] = ["m", "w"]
        html = helper.mailing_list_attributes_filter_info_items(list)
        expect(html).to include("<li>Geschlecht ist genau männlich oder weiblich</li>")
      end

      it "renders only one gender option" do
        filters[:timestamp][:value] = ["m"]
        html = helper.mailing_list_attributes_filter_info_items(list)
        expect(html).to include("<li>Geschlecht ist genau männlich</li>")
      end
    end
  end
end
