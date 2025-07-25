# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

# Lists callbacks
#
# Example:
#   list_callbacks(Person)
#   list_callbacks(PeopleController)
#
def list_callbacks(klass, skip_procs: true, skip_validations: true)
  klass.__callbacks.each_with_object(Hash.new { [] }) do |(k, callbacks), result|
    next if skip_validations && k == :validate # ignore validations
    callbacks.each do |c|
      next if skip_procs && c.filter.is_a?(Proc)
      # remove autosaving callbacks from result
      next if c.filter.to_s.include?("autosave")
      next if c.filter.to_s.include?("_ensure_no_duplicate_errors")
      result["#{c.kind}_#{c.name}"] += [c.filter]
    end.compact_blank
  end
end

def gr(resource, scope: nil, params: {}, ability: nil, as: Role.first.person)
  raise "#{resource} is not a resource class" unless resource <= ApplicationResource

  context = OpenStruct.new(current_ability: ability || Ability.new(as))
  Graphiti.with_context(context, params: params) do
    action_controller_params = ActionController::Parameters.new(params)
    resources = resource.all(action_controller_params, scope || resource.new.base_scope)
    JSON.parse(resources.to_jsonapi).deep_symbolize_keys
  end
end

# Setup PaperTrail metadata for the current pry session. If a block is given, the PaperTrail config
# is reverted to the previous state after the block is executed.
#
# Example:
#   with_papertrail_metadata do
#     user.update!(name: 'foo')
#   end
#
# or with the alias `pt`:
#   pt { user.update!(name: 'foo') }
def with_papertrail_metadata(whodunnit: "pry", mutation_id: "pry-#{SecureRandom.uuid}")
  controller_info = {mutation_id:}
  if whodunnit.is_a?(ActiveRecord::Base)
    controller_info[:whodunnit_type] = whodunnit.class.sti_name
    whodunnit = whodunnit.id
  end

  if block_given?
    PaperTrail.request(whodunnit:, controller_info:) { yield }
  else
    PaperTrail.request.whodunnit = whodunnit
    PaperTrail.request.controller_info = controller_info
  end
end

alias pt with_papertrail_metadata # rubocop:disable Style/Alias (alias_method is not available yet)

# When pry is started from the rails console. We set-up the PaperTrail metadata so that we can
# track all changes made during the console session.
if Rails.const_defined?(:Console)
  with_papertrail_metadata
end

def form_for(model, name: model.class.table_name.singularize, options: {})
  ActionController::Base.helpers.extend(UtilityHelper)
  StandardFormBuilder.new(model.class.name, model, ActionController::Base.helpers, options)
end
