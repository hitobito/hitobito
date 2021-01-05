# encoding: utf-8

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Messages::Letter
  class Content < Section

    def render(recipient)
      pdf.markup(replace_placeholders(@letter.content.to_s, recipient))
    end

    private

    def replace_placeholders(text, recipient)
      Export::Pdf::Messages::Letter::PLACEHOLDERS.each do |placeholder|
        placeholder_regex = Regexp.new("\\{#{placeholder.to_s}\\}")
        text = text.gsub(placeholder_regex, replacement(placeholder, recipient))
      end
      text
    end

    def replacement(placeholder, recipient)
      sanitize(send(placeholder, recipient))
    end

  end
end
