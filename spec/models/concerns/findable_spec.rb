# frozen_string_literal: true

#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe FindableByOrderedIdList do
  it "should raise exception when included in class that is not an Active Record model" do
    stub_const "Poro", Class.new

    expect do
      Poro.class_eval { include FindableByOrderedIdList }
    end.to raise_error("Module FindableByOrderedIdList can only be included in Active Record models")
  end

  it "should not raise exception when included in class that is an Active Record model" do
    stub_const "ArModel", Class.new(ActiveRecord::Base)

    expect do
      ArModel.class_eval { include FindableByOrderedIdList }
    end.not_to raise_error
  end

  it "should raise exception when calling check_findable_by_id on Active Record model without id column" do
    stub_const "NotFindable", Class.new(ActiveRecord::Base) { include FindableByOrderedIdList }
    allow(NotFindable).to receive(:column_names).and_return(["name", "age", "favorite_food"])

    expect do
      NotFindable.send(:check_findable_by_id, :some_method)
    end.to raise_error("Method some_method can only be used on Active Record models with an id column")
  end

  it "should not raise exception when calling check_findable_by_id on Active Record model with id column" do
    stub_const "IsFindable", Class.new(ActiveRecord::Base) { include FindableByOrderedIdList }
    allow(IsFindable).to receive(:column_names).and_return(["id", "hobby", "favorite_movie"])

    expect do
      IsFindable.send(:check_findable_by_id, :some_other_method)
    end.not_to raise_error
  end

  it "should return records ordered like given ids when calling find_by_ids_keeping_order" do
    message_recipients = 3.times.map { Fabricate(:message_recipient) }
    message_recipients.reverse!

    message_recipients_by_id = MessageRecipient.find_by_ids_keeping_order(message_recipients.pluck(:id))

    expect(message_recipients).to eq(message_recipients_by_id)
  end

  it "should return batch enumerator when calling find_in_ordered_batches" do
    message_recipient_ids = 10.times.map { Fabricate(:message_recipient).id }

    expect do
      MessageRecipient.find_in_ordered_batches(message_recipient_ids, batch_size: 3).each {}
    end.to make(4).db_queries

    expect do
      MessageRecipient.find_in_ordered_batches(message_recipient_ids, batch_size: 2).each {}
    end.to make(5).db_queries
  end
end
