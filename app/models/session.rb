# encoding: utf-8

# == Schema Information
#
# Table name: sessions
#
#  id         :integer          not null, primary key
#  data       :text(16777215)
#  created_at :datetime
#  updated_at :datetime
#  session_id :string(255)      not null
#
# Indexes
#
#  index_sessions_on_session_id  (session_id)
#  index_sessions_on_updated_at  (updated_at)
#


#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Session < ActiveRecord::Base

  def self.outdated
    where('updated_at < ?', 1.month.ago)
  end

end
