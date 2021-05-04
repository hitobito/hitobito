# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::Pdf::Messages::Letter
  class Content < Section

    class_attribute :placeholders
    self.placeholders = [:first_name, :last_name]

    def render(recipient)
      if dynamic?
        render_content recipient
      else
        stamped :render_content
      end
    end

    private

    def dynamic?
      @dynamic ||= placeholders.any? { |key| letter.body.to_s.include?(key.to_s) }
    end

    def render_content(recipient = nil)
      text = letter.body.to_s
      text = replace_placeholders(text, recipient) if recipient
      pdf.markup(text)
    end

    def replace_placeholders(text, recipient)
      placeholders.each do |placeholder|
        placeholder_regex = Regexp.new("\\{#{placeholder}\\}")
        text = text.gsub(placeholder_regex, replacement(placeholder, recipient))
      end
      text
    end

    def replacement(placeholder, recipient)
      sanitize(send(placeholder, recipient)).to_s
    end

    def first_name(person)
      person.first_name
    end

    def last_name(person)
      person.last_name
    end
  end
end
