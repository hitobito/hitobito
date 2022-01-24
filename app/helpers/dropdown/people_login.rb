# frozen_string_literal: true

# Copyright (c) 2022, hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https ://github.com/hitobito/hitobito.

module Dropdown
  class PeopleLogin < Base

    attr_reader :user

    def initialize(template, user, options = {})
      super(template, translate(:button), :lock)
      @user = user

      init_items
    end

    private

    def init_items
      send_login
      update_password
      activate_totp
      reset_totp
      disable_totp
    end

    def send_login
      if @user.email && (@user.roles.any? || @user.root?)
        add_item(translate('.send_login'), 
                 template.send_password_instructions_group_person_path(template.parent, @user),
                 method: :post,
                 rel: :tooltip,
                 'data-container' => 'body',
                 'data-html' => 'true',
                 title: template.send_login_tooltip_text,
                 remote: true)
      end
    end

    def update_password
      if @user == template.current_user && template.can?(:update_password, @user)
        add_item(I18n.t('devise.registrations.edit.change_password'),
                 template.edit_person_registration_path)
      end
    end

    def activate_totp
      if @user == template.current_user && !@user.two_factor_authentication_registered?
        add_item(translate('.activate_totp'),
                 template.new_users_second_factor_path(second_factor: 'totp'))
      end
    end

    def reset_totp
      if @user.two_factor_authentication_registered? && template.can?(:totp_reset, @user)
        add_item(translate('.reset_totp'),
                 template.totp_reset_group_person_path, method: :post)
      end
    end

    def disable_totp
      if @user.two_factor_authentication_registered? && template.can?(:totp_disable, @user)
        add_item(translate('.disable_totp'),
                 template.totp_disable_group_person_path, method: :post)
      end
    end
  end
end
