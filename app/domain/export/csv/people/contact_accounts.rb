# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Csv::People
  module ContactAccounts
    class << self
      def key(model, label)
        :"#{model.model_name.to_s.underscore}_#{label.downcase}"
      end

      def human(model, label)
        "#{model.model_name.human} #{label.capitalize}"
      end
    end
  end
end
