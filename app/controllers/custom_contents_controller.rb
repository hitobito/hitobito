# frozen_string_literal: true

#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CustomContentsController < SimpleCrudController
  self.permitted_attrs = [:label, :body, :subject] + CustomContent.globalize_attribute_names

  self.sort_mappings = {label: "custom_content_translations.label",
                         subject: "custom_content_translations.subject"}

  decorates :custom_content
end
