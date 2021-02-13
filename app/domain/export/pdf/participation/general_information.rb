#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Participation
  class GeneralInformation < Section
    def render
      return unless event_with_kind?
      render_general_information
    end

    private

    def render_general_information
      return if event.kind.try(:general_information).blank?

      with_header(I18n.t("activerecord.attributes.event/kind.general_information")) do
        text event.kind.general_information
      end
    end
  end
end
