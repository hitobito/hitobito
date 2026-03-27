#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PaperTrail
  class VersionAssociationChangePresenter
    attr_reader :version, :h

    delegate :event, :changeset, :item, :item_type, :main_type, :main_id, to: :version

    def initialize(version, view_context)
      @version = version
      @h = view_context
    end

    def render
      h.content_tag(:div) do
        changeset = (event == "update") ? changeset_list : nil
        item = reifyed_item

        text = association_change_text(changeset, item)

        h.sanitize(text, tags: %w[i])
      end
    end

    private

    def changeset_list
      presenter = PaperTrail::VersionChangesetPresenter.new(version, h)

      rendered_changes = changeset.map do |attr, (from, to)|
        presenter.attribute_change(attr, from, to)
      end

      h.safe_join(rendered_changes, ", ")
    end

    def association_change_text(changeset, item)
      return changeset if item_type.include?("Translation") && main_type

      if item_type == PeopleManager.sti_name
        return association_change_text_with_people_manager(changeset,
          item)
      end

      I18n.t("version.association_change.#{item_class.name.underscore}.#{event}",
        default: :"version.association_change.#{event}",
        model: item_class.model_name.human,
        label: item ? label_with_fallback(item) : "",
        changeset: changeset)
    end

    def association_change_text_with_people_manager(changeset, _item) # rubocop:todo Metrics/CyclomaticComplexity, Metrics/AbcSize
      # Since PeopleManager entries are either created or destroyed, accessing changes makes sense
      changes = version.send(:object_changes_deserialized)
      manager_id = changes["manager_id"].compact.first
      managed_id = changes["managed_id"].compact.first

      key, label = if manager_id == main_id
        ["managed", Person.find_by(id: managed_id)&.person_name]
      elsif managed_id == main_id
        ["manager", Person.find_by(id: manager_id)&.person_name]
      end

      I18n.t("version.association_change.#{item_class.name.underscore}.#{event}.#{key}",
        default: :"version.association_change.#{event}",
        model: item_class.model_name.human,
        label: label || "(#{I18n.t("version.association_change.deleted_person")})",
        changeset: changeset)
    end

    def reifyed_item
      if event == "create" || event == "removed"
        # "removed" is a custom event for habtm where only the join table is destroyed;
        # actual records still exist, so we reify_existing.
        reify_exisiting
      else
        reify(version)
      end
    end

    def reify(version)
      return version.reify unless item_class.column_names.include?("type")

      model_type = YAML.safe_load(
        version.object,
        permitted_classes: [Date, Time, Symbol]
      )["type"]

      Object.const_defined?(model_type) ? version.reify : Wrapped.new(model_type)
    end

    def reify_exisiting
      item || build_new_instance
    end

    def build_new_instance
      clazz = type_class_from_changeset || item_class
      clazz.new(attrs_from_changeset)
    end

    def attrs_from_changeset = changeset.transform_values(&:last)

    def type_class_from_changeset = attrs_from_changeset["type"]&.safe_constantize

    def item_class = @item_class ||= version.item_type.constantize

    def label_with_fallback(item)
      item.to_s(:long)
    rescue
      I18n.t("global.unknown")
    end
  end
end
