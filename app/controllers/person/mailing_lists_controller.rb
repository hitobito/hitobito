#  Copyright (c) 2020, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::MailingListsController < CrudController

  self.nesting = [Group, Person]

  alias_method :person, :parent

  private

  def list_entries
    Person::Subscriptions.new(person).mailing_lists.list
  end

  def authorize_class
    authorize!(:show_details, person)
  end
end

