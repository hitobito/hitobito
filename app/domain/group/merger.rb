# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Group::Merger

  attr_reader :group1, :group2, :new_group_name, :new_group, :errors

  def initialize(group1, group2, new_group_name)
    @group1 = group1
    @group2 = group2
    @new_group_name = new_group_name
  end

  def merge!
    raise('Cannot merge these Groups') unless group2_valid?

    ::Group.transaction do
      if create_new_group
        update_events
        copy_roles
        move_children
        move_invoices_and_articles
        delete_old_groups
      end
    end
  end

  def group2_valid?
    (group1.class == group2.class && group1.parent_id == group2.parent_id)
  end

  private

  def create_new_group
    new_group = build_new_group
    if new_group.save
      new_group.reload
      @new_group = new_group
      true
    else
      @errors = new_group.errors.full_messages
      false
    end
  end

  def build_new_group
    new_group = group1.class.new
    new_group.name = new_group_name
    new_group.parent_id = group1.parent_id
    new_group
  end

  def update_events
    events = (group1.events + group2.events).uniq
    events.each do |event|
      event.groups << new_group
      event.save!
    end
  end

  def move_children
    children = group1.children + group2.children
    children.each do |child|
      child.parent_id = new_group.id
      child.parent(true)
      child.save!
    end
  end

  def copy_roles
    roles = group1.roles + group2.roles
    roles.each do |role|
      new_role = role.dup
      new_role.group_id = new_group.id
      new_role.save!
    end
  end

  def move_invoices_and_articles
    invoices = group1.invoices + group2.invoices
    invoices.each do |invoice|
      invoice.group_id = new_group.id
      invoice.save!
    end

    invoice_articles = group1.invoice_articles + group2.invoice_articles
    invoice_articles.each do |invoice_article|
      invoice_article.group_id = new_group.id
      invoice_article.save!
    end
  end

  def delete_old_groups
    [group1, group2].each do |group|
      group.reload.destroy
    end
  end

end
