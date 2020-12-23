# encoding: utf-8

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Message
  class Content < Section

    def render(recipient)
      pdf.markup(replace_placeholders(@message.content.to_s, recipient))
    end

    private

    def replace_placeholders(text, recipient)
      Export::Pdf::Message::PLACEHOLDERS.each do |placeholder|
        text = text.gsub(Regexp.new("\\{#{placeholder.to_s}\\}"), replacement(placeholder, recipient))
      end
      text
    end

    def replacement(placeholder, recipient)
      sanitize(send(placeholder, recipient))
    end

  end
end
