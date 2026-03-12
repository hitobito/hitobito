module PaperTrail
  class VersionAuthorPresenter
    attr_reader :model, :h

    def initialize(model, view_context)
      @model = model
      @h = view_context
    end

    def render
      return if model.version_author.blank?

      case model.whodunnit_type
      when ServiceToken.sti_name then author_service_token
      when Person.sti_name then author_person
      else model.whodunnit_type
      end
    end

    private

    def author_person
      person = Person.find_by(id: model.version_author)
      return deleted_user_message unless person

      h.link_to_if(h.can?(:show, person), person.to_s, h.person_path(person.id))
    end

    def author_service_token
      token = ServiceToken.find_by(id: model.version_author)
      return deleted_service_token_message unless token

      label = "#{ServiceToken.model_name.human}: #{token}"
      h.link_to_if(h.can?(:show, token), label,
        h.group_service_token_path(token.layer_group_id, token.id))
    end

    def deleted_user_message
      I18n.t("version.deleted_user", id: model.version_author)
    end

    def deleted_service_token_message
      I18n.t("version.deleted_service_token", model_name: ServiceToken.model_name.human)
    end
  end
end
