# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# rubocop:disable Rails/HelperInstanceVariable This is a domain-class in the wrong directory

module Dropdown
  class GroupEdit < Base

    attr_reader :group

    def initialize(template, group)
      super(template, template.ti('link.edit'), :edit)

      @group = group
      @main_link = (group.archived? ? nil : template.edit_group_path(group))

      init_items
    end

    private

    def init_items # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      unless group.archived? || merge_candidates?
        add_item(translate(:merge), template.merge_group_path(group))
      end

      unless group.archived? || move_candidates?
        add_item(translate(:move), template.move_group_path(group))
      end

      if group.archivable?
        add_item(translate(:archive), template.archive_group_path(group),
                 data: { confirm: template.ti(:confirm_archive), method: :post })
      end

      if !group.protected? && template.can?(:destroy, group)
        add_divider unless group.archived?
        add_item(template.ti('link.delete'), template.group_path(group),
                 data: { confirm: template.ti(:confirm_delete), method: :delete })
      end
    end

    def merge_candidates?
      groups = group.sister_groups
      @candidates = groups.select {|group| template.can?(:update, group) }
      @candidates.empty? 
    end

    def move_candidates?
      @candidates = mover.candidates.select { |candidate| template.can?(:update, candidate) }.
                                     group_by { |candidate| candidate.class.label }
      @candidates.values.each { |groups| groups.sort_by(&:name) }
      @candidates.empty?
      
    end

    def mover
      @mover ||= Group::Mover.new(group)
    end
  end
end
# rubocop:enable Rails/HelperInstanceVariable
