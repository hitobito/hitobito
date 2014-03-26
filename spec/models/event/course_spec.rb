# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: events
#
#  id                     :integer          not null, primary key
#  type                   :string(255)
#  name                   :string(255)      not null
#  number                 :string(255)
#  motto                  :string(255)
#  cost                   :string(255)
#  maximum_participants   :integer
#  contact_id             :integer
#  description            :text
#  location               :text
#  application_opening_at :date
#  application_closing_at :date
#  application_conditions :text
#  kind_id                :integer
#  state                  :string(60)
#  priorization           :boolean          default(FALSE), not null
#  requires_approval      :boolean          default(FALSE), not null
#  created_at             :datetime
#  updated_at             :datetime
#  participant_count      :integer          default(0)
#  application_contact_id :integer
#  external_applications  :boolean          default(FALSE)
#

require 'spec_helper'

describe Event::Course do

  subject do
    Fabricate(:course, groups: [groups(:top_group)])
  end

  its(:qualification_date) { should == Date.new(2012, 5, 11) }

  context '#qualification_date' do
    before do
      subject.dates.destroy_all
      add_date('2011-01-20')
      add_date('2011-02-15')
      add_date('2011-01-02')
    end

    its(:qualification_date) { should == Date.new(2011, 02, 20) }

    def add_date(start_at, event = subject)
      start_at = Time.zone.parse(start_at)
      event.dates.create(start_at: start_at, finish_at: start_at + 5.days)
    end
  end

  context 'multiple start_at' do
    before { subject.dates.create(start_at: Date.new(2012, 5, 14)) }
    its(:qualification_date) { should == Date.new(2012, 5, 14) }
  end


end
