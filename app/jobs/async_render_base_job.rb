#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AsyncRenderBaseJob < BaseJob
  self.parameters = [:locale, :user_id, :target_dom_id, :options]

  attr_reader :user_id, :target_dom_id, :options

  def initialize(user_id, target_dom_id, options = {})
    super()
    @user_id = user_id
    @target_dom_id = target_dom_id
    @options = options
  end

  def perform
    set_locale

    Turbo::StreamsChannel.broadcast_replace_to(
      channel_name,
      target: target_dom_id,
      html: ApplicationController.render(partial: partial_name,
        locals: {data: data, target_dom_id: target_dom_id})
    )
  end

  def partial_name
    raise NotImplementedError, "Subclasses must implement #partial_name"
  end

  def data
    raise NotImplementedError, "Subclasses must implement #data"
  end

  def channel_name = "user_#{user_id}_async_updates"

  def user = @user ||= Person.find(user_id)

  def ability = @ability ||= Ability.new(user)
end
