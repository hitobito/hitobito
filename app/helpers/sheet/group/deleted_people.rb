#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  class Group
    class DeletedPeople < Group
      self.tabs = []

      def title
        I18n.t("groups.global.link.deleted_person")
      end

      def active_tab
        nil
      end

      private

      def breadcrumbs?
        true
      end

      def breadcrumbs
        entry.hierarchy.collect do |g|
          link_to(g.to_s, group_path(g))
        end
      end

      def model_name
        "group"
      end

      def translation_prefix
        "sheet/group"
      end
    end
  end
end
