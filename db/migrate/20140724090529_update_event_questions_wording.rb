# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class UpdateEventQuestionsWording < ActiveRecord::Migration
  def change
    Event::Question.find_by(event_id: nil,
                            question: 'Ich habe folgendes ÖV Abo').
                            update_attribute(:question, 'Ich habe während dem Kurs folgendes ÖV Abo')
  end
end
