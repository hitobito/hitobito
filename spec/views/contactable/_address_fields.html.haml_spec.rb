# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "contactable/_address_fields.html.haml" do
  let(:form_without_address_addition) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes

      def self.model_name = ActiveModel::Name.new(self, nil, "SignupPerson")

      %i[address_care_of street housenumber postbox zip_code town country].each do |attr|
        attribute attr, :string
      end
    end.new
  end

  let(:dom) { Capybara::Node::Simple.new(rendered) }

  def render_for(object, name)
    render partial: "contactable/address_fields",
      locals: {f: StandardFormBuilder.new(name, object, view, {})}
  end

  it "renders address_addition after address_care_of" do
    render_for(people(:top_leader), :person)

    expect(dom).to have_field("person_address_care_of")
    expect(dom).to have_field("person_address_addition")
  end

  it "omits address_addition for form objects without that attribute" do
    render_for(form_without_address_addition, :signup_person)

    expect(dom).to have_field("signup_person_address_care_of")
    expect(dom).not_to have_field("signup_person_address_addition")
  end
end
