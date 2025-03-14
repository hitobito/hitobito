# frozen_string_literal: true

#  Copyright (c) 2014-2024 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# rubocop:disable Rails/HelperInstanceVariable this domain-class is in the wrong directory

module Sheet
  class Hour
    class NavLeft
      attr_reader :entry, :sheet, :view

      delegate :content_tag, :link_to, :safe_join, :sanitize, :request, to: :view

      def initialize(sheet)
        @sheet = sheet
        @entry = sheet.entry
        @view = sheet.view
      end

      def render
        items = []
        items << content_tag(:li, class: ("is-active" if active?("approve"))) do
          link_to("Approved", "/en/hours/approve")
        end
        
        # items << content_tag(:li, class: ("is-active" if active?("hours_summary"))) do
        #   link_to("Hours Summary", "/en/hours/hours_summary")
        # end        
      
        content_tag(:ul, class: "nav-left-list") do
          safe_join(items)
        end
      end

      private

      def active?(tab_name)
        request.fullpath.include?(tab_name)
      end
    end
  end
end

# rubocop:enable Rails/HelperInstanceVariable
