# encoding: utf-8

#  Copyright (c) 2014, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


# == Schema Information
#
# Table name: people_relations
#
#  id      :integer          not null, primary key
#  head_id :integer          not null
#  tail_id :integer          not null
#  kind    :string(255)      not null
#
class PeopleRelation < ActiveRecord::Base

  belongs_to :head, class_name: 'Person'
  belongs_to :tail, class_name: 'Person'

end
