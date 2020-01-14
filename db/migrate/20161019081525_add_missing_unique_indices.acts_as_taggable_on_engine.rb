# encoding: utf-8

#  Copyright (c) 2016, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# This migration comes from acts_as_taggable_on_engine (originally 2)
class AddMissingUniqueIndices < ActiveRecord::Migration[4.2]
  def self.up
    add_index :tags, :name, unique: true

    remove_index :taggings, :tag_id if index_exists?(:taggings, :tag_id)
    remove_index :taggings, [:taggable_id, :taggable_type, :context]
    add_index :taggings,
              [:tag_id, :taggable_id, :taggable_type, :context, :tagger_id, :tagger_type],
              unique: true, name: 'taggings_idx'
  end

  def self.down
    remove_index :tags, :name

    remove_index :taggings, name: 'taggings_idx'

    add_index :taggings, :tag_id unless index_exists?(:taggings, :tag_id)
    add_index :taggings, [:taggable_id, :taggable_type, :context]
  end
end
