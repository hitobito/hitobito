# encoding: utf-8

#  Copyright (c) 2012-2020 Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

require 'spec_helper'

describe Event::ParticipationContactDatasController do

  before { sign_in(top_leader) }

  let(:top_leader) { people(:top_leader) }
  let(:group)      { groups(:top_group) }
  let(:course)     { Fabricate(:course, groups: [group]) }
  let(:entry)      { assigns(:participation_contact_data) }

  context 'PATCH#update' do
    context 'with privacy policies in hierarchy' do
      before do
        file = Rails.root.join('spec', 'fixtures', 'files', 'images', 'logo.png')
        image = ActiveStorage::Blob.create_after_upload!(io: File.open(file, 'rb'),
                                                         filename: 'logo.png',
                                                         content_type: 'image/png').signed_id
        group.layer_group.update(privacy_policy: image)

      end

      it 'creates person if privacy policy is accepted' do
        course.update!(required_contact_attrs: [])

        patch :update, params: {
          group_id: group.id,
          event_id: course.id,
          event_participation_contact_data: {
            email: top_leader.email,
            first_name: top_leader.first_name,
            last_name: 'NewName',
            privacy_policy_accepted: '1'
          },
          event_role: {
            type: 'Event::Role::Participant'
          }
        }

        expect(entry).to have(0).errors
        expect(top_leader.reload.privacy_policy_accepted).to be_present
      end

      it 'does not create a person if privacy policy is not accepted' do
        course.update!(required_contact_attrs: [])

        patch :update, params: {
          group_id: group.id,
          event_id: course.id,
          event_participation_contact_data: {
            email: top_leader.email,
            first_name: top_leader.first_name,
            last_name: 'NewName',
            privacy_policy_accepted: '0'
          },
          event_role: {
            type: 'Event::Role::Participant'
          }
        }

        expect(entry).to have(1).errors
        expect(entry.errors.full_messages).to eq(['Um die Anmeldung abzuschliessen, muss der Datenschutzerklärung zugestimmt werden.'])
        expect(top_leader.reload.privacy_policy_accepted).to_not be_present
      end
    end

    it 'validates default attrs' do
      # course.update(required_contact_attrs: %w(phone_numbers))
      patch :update, params: {
        group_id: group.id,
        event_id: course.id,
        event_participation_contact_data: {},
      }
      expect(entry).to have(3).errors
      expect(entry.errors.attribute_names).to match_array([:email, :first_name, :last_name])
    end

    it 'validates phone_number' do
      course.update(required_contact_attrs: %w(phone_numbers))
      patch :update, params: {
        group_id: group.id,
        event_id: course.id,
        event_participation_contact_data: {
          email: top_leader.email,
          first_name: top_leader.first_name,
          last_name: 'NewName',
          phone_numbers_attributes: {
          }
        },
        event_role: {
          type: 'Event::Role::Participant'
        }
      }
      expect(entry).to have(1).errors
      expect(entry.errors.attribute_names).to match_array([:phone_numbers])
    end

    it 'stores attributes on person if valid' do
      course.update(required_contact_attrs: %w(phone_numbers))
      number = top_leader.phone_numbers.create!(label: 'dummy', number: '+41790000000')
      patch :update, params: {
        group_id: group.id,
        event_id: course.id,
        event_participation_contact_data: {
          email: top_leader.email,
          first_name: top_leader.first_name,
          last_name: 'NewName',
          phone_numbers_attributes: {
            '1' => { id: number.id, label: number.label, number: '+41791111111', _destroy: false }
          }
        },
        event_role: {
          type: 'Event::Role::Participant'
        }
      }
      expect(entry).to have(0).errors
      expect(top_leader.reload.last_name).to eq 'NewName'
    end
  end


end
