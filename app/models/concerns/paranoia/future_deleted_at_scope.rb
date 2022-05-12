#  Copyright (c) 2022, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Paranoia
  module FutureDeletedAtScope
    extend ActiveSupport::Concern
    
    # Overwriting acts_as_paranoid here, see https://github.com/hitobito/hitobito/issues/1714
    included do
      default_scope { without_deleted }

      scope :without_deleted, -> {      
        unscope(where: :"#{table_name}.#{paranoia_column}")
          .where("#{table_name}": { "#{paranoia_column}": nil })
          .or(unscoped.where(arel_table[:"#{paranoia_column}"].gt(Time.zone.now)))
      }

      scope :with_deleted, -> { unscope(where: :"#{table_name}.#{paranoia_column}") }

      scope :only_deleted, -> { 
        unscope(where: :"#{table_name}.#{paranoia_column}")
          .where.not("#{table_name}": { "#{paranoia_column}": nil })
          .where("#{table_name}": { "#{paranoia_column}": ..Time.zone.now })
      }


      def deleted?
        return false if send(paranoia_column).nil?

        send(paranoia_column) <= Time.zone.now
      end
    end

  end
end
