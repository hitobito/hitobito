# frozen_string_literal: true

#  Copyright (c) 2015-2024, Pro Natura Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: event_attachments
#
#  id         :integer          not null, primary key
#  event_id   :integer          not null
#  visibility :string(255)
#

require 'spec_helper'

describe Event::Attachment do

  let(:event) { events(:top_event) }

  context 'file_size' do
    it 'validates maximum' do
      a = event.attachments.new
      file = Tempfile.new(['x', '.png'])
      File.write(file, 'x' * 12.megabytes)
      a.file.attach(io: file, filename: 'foo.png')
      expect(a).not_to be_valid
      expect(a.errors.full_messages.join).to match(/muss kleiner oder gleich 2 MB/)
    end
  end

  context 'visibility' do
    it 'allows setting visibility' do
      a = event.attachments.new
      file = Tempfile.new(['x', '.png'])
      File.write(file, 'x' * 1.megabytes)
      a.file.attach(io: file, filename: 'foo.png')
      expect { a.visibility = :participants }.not_to raise_error
    end

    it 'validates visibility' do
      a = event.attachments.new
      file = Tempfile.new(['x', '.png'])
      File.write(file, 'x' * 1.megabytes)
      a.file.attach(io: file, filename: 'foo.png')
      expect { a.visibility = :foo }.to raise_error("'foo' is not a valid visibility")
    end
  end
end
