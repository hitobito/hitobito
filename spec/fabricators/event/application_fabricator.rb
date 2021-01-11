# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: event_applications
#
#  id                   :integer          not null, primary key
#  approved             :boolean          default(FALSE), not null
#  rejected             :boolean          default(FALSE), not null
#  waiting_list         :boolean          default(FALSE), not null
#  waiting_list_comment :text(16777215)
#  priority_1_id        :integer          not null
#  priority_2_id        :integer
#  priority_3_id        :integer
#

Fabricator(:event_application, class_name: 'Event::Application') do
  priority_1    { Fabricate(:course) }
  priority_2    { Fabricate(:course) }
end
