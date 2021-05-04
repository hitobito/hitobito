# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::Pdf::Messages::Letter
  class Section < Export::Pdf::Section
    include ActionView::Helpers::SanitizeHelper


    delegate :recipients, :content, to: :message

    alias_method :letter, :model


    private

    def with_settings(opts = {})
      before = opts.map { |key, _value| [key, pdf.send(key)] }
      opts.each { |key, value| pdf.send(:"#{key}=", value) }
      yield
      before.each { |key, value| pdf.send(:"#{key}=", value) }
    end

    def text(*args)
      options = args.extract_options!
      pdf.text args.join(' '), options
    end

  end
end
