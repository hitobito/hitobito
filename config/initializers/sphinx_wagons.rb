# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module ThinkingSphinx
  class Index

    class_attribute :partial_indices

    class << self
      def define_partial(reference, &block)
        self.partial_indices ||= Hash.new { |h, k| h[k] = [] }
        self.partial_indices[reference] << block
      end

      def define_partial_indizes!
        ThinkingSphinx::Configuration.instance.preload_indices

        if partial_indices.present?

          partial_indices.each do |reference, blocks|
            #puts "defining #{blocks.size} indizes for #{reference}"
            define(reference, with: :active_record) do
              blocks.each { |b| self.instance_eval(&b) }
            end
          end
        end
      end
    end

  end
end


