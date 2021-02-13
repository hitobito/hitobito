# frozen_string_literal: true

#  Copyright (c) 2020, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe LayoutHelper do
  include Webpacker::Helper

  describe "#header_logo" do
    let(:group) { groups(:bottom_group_one_one_one) }
    let(:parent) { groups(:bottom_group_one_one) }
    let(:grandparent) { groups(:bottom_layer_one) }
    let(:app_logo) { "/packs-test/media/images/logo-[0-9a-f]+.png" }

    before { assign(:group, group) }

    it "should find the logo directly on the visible group" do
      group.update(logo: File.open("spec/fixtures/person/test_picture.jpg"))

      expect(helper.header_logo).to eql("<img src=\"#{asset_path(group.logo)}\" />")
    end

    it "should find the logo on a parent group" do
      parent.update(logo: File.open("spec/fixtures/person/test_picture2.jpg"))
      expect(helper.header_logo).to eql("<img src=\"#{asset_path(parent.logo)}\" />")
    end

    it "should return the correct logo, when multiple are available." do
      grandparent.update(logo: File.open("spec/fixtures/person/test_picture2.jpg"))
      parent.update(logo: File.open("spec/fixtures/person/test_picture.jpg"))

      expect(helper.header_logo).to eql("<img src=\"#{asset_path(parent.logo)}\" />")
    end

    it "should return nil when not viewing a group" do
      assign(:group, nil)

      expect(helper.header_logo).to match Regexp.new("<img alt=\"hitobito\" src=\"#{app_logo}\" />")
    end

    it "should return nil when no logo is set" do
      expect(helper.header_logo).to match Regexp.new("<img alt=\"hitobito\" src=\"#{app_logo}\" />")
    end
  end

  context "#icon" do
    it "emits an html-tag with the icon css-class" do
      expect(helper.icon(:edit)).to eq('<i class="fa fa-edit"></i>')
    end

    it "dasherizes the css-class" do
      expect(extract_classes(helper.icon(:hand_point_up))).to include("fa-hand-point-up")
    end

    it "uses the filled-form by default" do
      expect(extract_classes(helper.icon(:edit))).to include("fa")
    end

    it "can add the non-filled form" do
      expect(extract_classes(helper.icon(:edit, filled: false))).to include("far")
    end

    # sorry for this violation of demeter
    def extract_classes(tag_string)
      Nokogiri::HTML.fragment(tag_string) # NodeSet
                    .children # Array
                    .first # Element
                    .attributes["class"] # Attr
                    .value # String
                    .split(" ")
    end
  end
end
