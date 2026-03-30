module ApiScopeAbility
  extend ActiveSupport::Concern

  REQUIRED_SCOPES = {
    Role: [:groups, :people],
    "Event::Kind": :events,
    "Event::KindCategory": :events,
    InvoiceItem: :invoices
  }.with_indifferent_access

  private

  # Override the method used in Ability to collect all permission declarations from the ability
  # classes. After the ability store has gathered them, we filter the gathered configs
  # by the criteria on the token, so that we only grant permissions which are a) given to the
  # user and b) activated on the token.
  def define_user_abilities(current_store, current_user_context, include_manageds = true)
    limited_store = current_store.filter_configs do |permission, subject_class, action, config|
      inherit_user_ability?(permission, subject_class, action, config)
    end

    super(limited_store, current_user_context, include_manageds)
  end

  # Only consider permissions which match the token permission and scope settings
  def inherit_user_ability?(_permission, subject_class, action, _config)
    subject_class_name = base_class_name_from(subject_class)
    (action_acceptable?(action) && model_acceptable?(subject_class_name)) ||
      acceptable_special_case?(subject_class_name, action)
  end

  # Only apply permissions where the action matches the token permissions
  def action_acceptable?(action)
    case action.to_sym
    when :show, :show_full, :show_details, :index, :list_available, :read
      true
    when :create, :update, :destroy, :manage
      write_permission?
    end
  end

  # Only apply permissions where the model matches the available scopes
  def model_acceptable?(subject_class_name)
    if REQUIRED_SCOPES.key?(subject_class_name)
      return Array(REQUIRED_SCOPES[subject_class_name]).all? do |scope|
        acceptable?(scope)
      end
    end

    scope = subject_class_name.gsub("::", "").pluralize.underscore
    ServiceToken.possible_scopes.include?(scope) && acceptable?(scope)
  end

  # In some cases, the accessed model does not match the required scope,
  # e.g. the people scope can grant a permission on Group, :index_people
  def acceptable_special_case?(subject_class_name, action)
    case [subject_class_name, action.to_sym]
    when ["Group", :index_people]
      acceptable?(:people)
    when ["Group", :index_events], ["Group", :"index_event/courses"]
      acceptable?(:events)
    when ["Group", :index_issued_invoices]
      acceptable?(:invoices)
    when ["Group", :index_mailing_lists]
      acceptable?(:mailing_lists)
    when ["Event", :index_participations], ["Event::Course", :index_participations]
      # Only in the legacy API, participations are also fetchable with the events scope
      acceptable?(:events)
    end
  end

  def base_class_name_from(model_class)
    return model_class.base_class.name if model_class.respond_to?(:base_class)
    model_class.name
  end
end
