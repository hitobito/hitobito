# encoding: utf-8

#  Copyright (c) 2012-2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailchimpDestructionJob < BaseJob
  self.parameters = [:mailchimp_list_id, :mailchimp_api_key, :people_to_be_deleted]

  def initialize(mailchimp_list_id, mailchimp_api_key, people_to_be_deleted)
    super()
    @mailchimp_list_id = mailchimp_list_id
    @mailchimp_api_key = mailchimp_api_key
    @people_to_be_deleted = people_to_be_deleted
  end

  def perform
    Synchronize::Mailchimp::Destroyer.new(@mailchimp_list_id,
                                          @mailchimp_api_key,
                                          @people_to_be_deleted).call
  end

end
