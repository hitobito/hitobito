# encoding: utf-8

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Messages::Letter
  class Section
    include ActionView::Helpers::SanitizeHelper

    attr_reader :pdf, :message, :exporter

    class_attribute :model_class

    delegate :bounds, :bounding_box, :table, :cursor, :font_size, :text_box,
             :fill_and_stroke_rectangle, :fill_color, :image, :group, to: :pdf

    delegate :recipients, :content, to: :message

    delegate *Export::Pdf::Messages::Letter::PLACEHOLDERS, to: :exporter

    def initialize(pdf, letter, exporter)
      @pdf = pdf
      @letter = letter
      @exporter = exporter
    end

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
