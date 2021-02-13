# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::List
  class Section
    attr_reader :pdf, :contactables, :group

    delegate :bounds, :bounding_box, :cursor, :font_size, to: :pdf

    def initialize(pdf, contactables, group)
      @pdf = pdf
      @contactables = contactables
      @group = group
    end

    private

    def text(*args)
      options = args.extract_options!
      pdf.text args.join(" "), options
    end

    def move_down_line(line = 10)
      pdf.move_down(line)
    end
  end
end
