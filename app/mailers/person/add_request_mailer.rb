# encoding: utf-8

#  Copyright (c) 2012-2015 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::AddRequestMailer < ApplicationMailer

  def ask_person_to_add(request)

  end

  def ask_responsibles(request, responsibles)
    Person.mailing_emails_for(responsibles)
  end

  def approved(person, body, requester, user)

  end

  def rejected(person, body, requester, user)

  end

end
