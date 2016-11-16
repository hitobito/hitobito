# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz, Pfadibewegung Schweiz.
#  This file is part of hitobito and licensed under the Affero General Public
#  License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.


module Export::Csv
  # The base class for all the different csv export files.
  class Base < ::Export::Base

    class_attribute :model_class, :row_class
    self.row_class = Row

    class << self
      def export(*args)
        Export::Csv::Generator.new(new(*args)).csv
      end
    end

    def to_csv(generator)
      generator << labels
      list.each do |entry|
        generator << values(entry)
      end
    end
  end
end
