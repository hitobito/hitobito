# encoding: utf-8

#  Copyright (c) 2014, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'oat/adapters/json_api'

class ApplicationSerializer < Oat::Serializer
  adapter Oat::Adapters::JsonAPI

  class << self
    # define a schema extension for a given key
    def extension(key, &block)
      @extensions ||= Hash.new { |h, k| h[k] = [] }
      @extensions[key] << block if block_given?
      @extensions[key]
    end
  end

  # include schema extensions for a given key from wagons
  def apply_extensions(key, options = {})
    self.class.extension(key).each do |block|
      instance_exec(options, &block)
    end
  end

  # properties used for a json api resource
  def json_api_properties
    type type_name
    property :id, item.id.to_s
    property :type, type_name
  end

  def modification_properties
    map_properties :created_at, :updated_at

    entity :creator, item.creator_id, PersonIdSerializer
    entity :updater, item.updater_id, PersonIdSerializer

    person_template_link "#{type_name}.creator"
    person_template_link "#{type_name}.updater"

    if item.respond_to?(:deleted_at)
      map_properties :deleted_at
      entity :deleter, item.deleter_id, PersonIdSerializer
      person_template_link "#{type_name}.deleter"
    end
  end

  # accessor for controller methods such as url helpers
  # or can? calls.
  def h
    context[:controller]
  end

  # alternative to store custom link templates
  def template_link(key, type, href, options = {})
    template_links[key] = options.merge(href: href.gsub('%7B', '{').gsub('%7D', '}'),
                                        type: type.to_s.pluralize)
  end

  def group_template_link(key)
    template_link(key, :groups, h.group_url("{#{key}}", format: :json))
  end

  def person_template_link(key)
    template_link(key, :people, h.person_url("{#{key}}", format: :json))
  end

  # fix some issues from oat
  def to_hash
    super.tap do |hash|
      unify_linked_entries(hash)
      add_template_links(hash)
    end
  end

  def type_name
    @type_name ||= item.class.base_class.model_name.plural
  end

  protected

  def template_links
    if top == self
      @template_links ||= {}
    else
      top.template_links
    end
  end

  private

  def unify_linked_entries(hash)
    return unless hash.key?(:linked)

    linked_full = hash.delete(:linked)
    hash[:linked] = Hash.new { |h, k| h[k] = [] }
    linked_full.each do |link, objects|
      objects.each do |attrs|
        type = attrs.delete(:type)
        # do not add attrs consisting only of an :id
        unless attrs.keys.collect(&:to_s) == %w(id)
          # combine linked entries by type
          list = hash[:linked][type || link]
          unless list.include?(attrs)
            list << attrs
          end
        end
      end
    end
  end

  def add_template_links(hash)
    return if top != self || template_links.blank?
    hash[:links] ||= {}
    hash[:links].merge!(template_links)
  end

end