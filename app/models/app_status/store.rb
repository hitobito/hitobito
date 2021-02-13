# encoding: utf-8

#  Copyright (c) 2017, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AppStatus::Store < AppStatus
  def initialize
    @store_ok = store_ok?
  end

  def details
    {store_ok?: @store_ok}
  end

  def code
    @store_ok ? :ok : :service_unavailable
  end

  private

  def store_ok?
    folder = Rails.root.join("public")
    File.directory?(folder) && File.writable?(folder)
  end
end
