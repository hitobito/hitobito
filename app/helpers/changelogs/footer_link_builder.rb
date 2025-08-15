#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Changelogs
  class FooterLinkBuilder
    include ActionView::Helpers::OutputSafetyHelper

    SOURCE_CODE_URL = "https://github.com/hitobito"
    LICENSE_URL = "http://www.gnu.org/licenses/agpl-3.0.html"
    LICENSE_NAME = "GNU Affero General Public License"
    DEVELOPER_URL = "http://hitobito.ch"
    DEVELOPER_NAME = "Hitobito"

    attr_accessor :template

    delegate :content_tag, :changelog_path, :link_to, :app_version_links, :t, :tag, to: :template

    def initialize(template)
      @template = template
    end

    def render
      safe_join([collapse_toggle_link, version_label, detail_info_div])
    end

    private

    def collapse_toggle_link
      content_tag(:a, content_tag(:i, "", class: "fas fa-chevron-right mr-2"),
        data: {bs_toggle: "collapse"}, href: "#detail-info")
    end

    def version_label(display_as_link: true)
      if Wagons.app_version.to_s > "0.0"
        if display_as_link
          link_to("Version #{Wagons.app_version}", changelog_path)
        else
          "Version #{Wagons.app_version}"
        end
      end
    end

    def detail_info_div
      content_tag(:div, class: "collapse", id: "detail-info") do
        safe_join(detail_info_content, " ")
      end
    end

    def detail_info_content
      [
        app_version_links,
        link_to(t(".source_code"), SOURCE_CODE_URL, target: "_blank", rel: "noopener"),
        t(".available_under_license"),
        link_to(LICENSE_NAME, LICENSE_URL, target: "_blank", rel: "noopener"),
        tag.br,
        t(".developed_by"),
        link_to(DEVELOPER_NAME, DEVELOPER_URL, target: "_blank", rel: "noopener"),
        " 2012 - #{Time.zone.now.year}".html_safe
      ]
    end
  end
end
