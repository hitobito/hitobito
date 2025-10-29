# frozen_string_literal: true

#  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe GlobalizedPermittedAttrs do
  include GlobalizedTestModels

  let(:permitted_attrs) { [:title, :body, { comment_attributes: [:title, :content] }] }

  let(:globalized_permitted_attrs) do
    described_class.new(GlobalizedTestModels::Post, permitted_attrs).permitted_attrs
  end

  it "adds globalized version of permitted attrs except for current locale" do
    expected_attrs = attrs_with_globalized_versions(:title, :body)

    expect(globalized_permitted_attrs).to include(*expected_attrs)
    expect(globalized_permitted_attrs).not_to include(:title_de, :body_de)
  end

  it "adds globalized version of permitted attrs except for current locale when locale is changed" do
    I18n.locale = :fr
    expected_attrs = attrs_with_globalized_versions(:title, :body)

    expect(globalized_permitted_attrs).to include(*expected_attrs)
    expect(globalized_permitted_attrs).not_to include(:title_fr, :body_fr)
  end

  it "doesnt add globalized version of permitted attrs when base attr not permitted" do
    permitted_attrs.delete(:body)

    expected_attrs = attrs_with_globalized_versions(:title)
    unexpected_attrs = attrs_with_globalized_versions(:body, only_additional: false)

    expect(globalized_permitted_attrs).to include(*expected_attrs)
    expect(globalized_permitted_attrs).not_to include(*unexpected_attrs)
  end

  it "adds globalized version of permitted attrs for relations except for current locale" do
    globalized_comment_permitted_attrs = globalized_permitted_attrs.find { |attr| attr.is_a? Hash }[:comment_attributes]

    expected_attrs = attrs_with_globalized_versions(:title, :content)

    expect(globalized_comment_permitted_attrs).to include(*expected_attrs)
    expect(globalized_comment_permitted_attrs).not_to include(:title_de, :content_de)
  end

  it "adds globalized version of permitted attrs for relations except for current locale when locale is changed" do
    I18n.locale = :en
    globalized_comment_permitted_attrs = globalized_permitted_attrs.find { |attr| attr.is_a? Hash }[:comment_attributes]

    expected_attrs = attrs_with_globalized_versions(:title, :content)

    expect(globalized_comment_permitted_attrs).to include(*expected_attrs)
    expect(globalized_comment_permitted_attrs).not_to include(:title_en, :content_en)
  end

  it "doesnt add globalized version of permitted attrs for relations when base attr not permitted" do
    permitted_attrs.find { |attr| attr.is_a? Hash }[:comment_attributes].delete(:content)
    globalized_comment_permitted_attrs = globalized_permitted_attrs.find { |attr| attr.is_a? Hash }[:comment_attributes]

    expected_attrs = attrs_with_globalized_versions(:title)
    unexpected_attrs = attrs_with_globalized_versions(:content, only_additional: false)

    expect(globalized_comment_permitted_attrs).to include(*expected_attrs)
    expect(globalized_comment_permitted_attrs).not_to include(*unexpected_attrs)
  end

  def attrs_with_globalized_versions(*attrs, only_additional: true)
    (attrs + attrs.map { |attr| Globalized.globalized_names_for_attr(attr, only_additional) }).flatten
  end
end
