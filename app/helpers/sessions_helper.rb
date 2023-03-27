module SessionsHelper
  def render_self_registration_link
    return unless FeatureGate.enabled?('groups.self_registration')

    group = Group.find_by(main_self_registration_group: true)
    if group&.self_registration_active?
      link_to t('layouts.unauthorized.main_self_registration'), group_self_registration_path(group_id: group.id)
    end
  end
end
