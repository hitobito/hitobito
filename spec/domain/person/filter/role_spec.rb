#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Person::Filter::Role do
  let(:user) { people(:top_leader) }
  let(:group) { groups(:top_group) }
  let(:range) { nil }

  context "initialize" do
    it "ignores unknown role types" do
      filter = Person::Filter::Role.new(:role, role_types: %w[Group::TopGroup::Leader Group::BottomGroup::OldRole File Group::BottomGroup::Member])
      expect(filter.to_hash).to eq(role_types: %w[Group::TopGroup::Leader Group::BottomGroup::Member])
    end

    it "ignores unknown role ids" do
      filter = Person::Filter::Role.new(:role, role_type_ids: %w[1 304 3 judihui])
      expect(filter.to_params).to eq(role_type_ids: "1-3")
    end

    it "is considered blank if no role_type_ids are set" do
      filter = Person::Filter::Role.new(:role, role_type_ids: %w[])
      expect(filter).to be_blank
    end

    %w[active deleted].each do |kind|
      it "is not considered blank if kind #{kind} but no role_type_ids are set" do
        filter = Person::Filter::Role.new(:role, role_type_ids: %w[], kind: kind)
        expect(filter).not_to be_blank
      end
    end
  end

  context "filtering" do
    let(:list_filter) do
      Person::Filter::List.new(group,
        user,
        range: range,
        filters: {
          role: {role_type_ids: role_type_ids_string}
        })
    end

    let(:entries) { list_filter.entries }
    let(:range) { nil }
    let(:role_types) { [] }
    let(:role_type_ids_string) { role_types.collect(&:id).join(Person::Filter::Role::ID_URL_SEPARATOR) }

    before do
      @tg_member = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)).person
      Fabricate(:phone_number, contactable: @tg_member, number: "+41 44 123 45 67", label: "Privat", public: true)
      Fabricate(:phone_number, contactable: @tg_member, number: "+41 77 456 78 90", label: "Mobile", public: false)
      Fabricate(:social_account, contactable: @tg_member, name: "facefoo", label: "Facebook", public: true)
      Fabricate(:social_account, contactable: @tg_member, name: "skypefoo", label: "Skype", public: false)
      # duplicate role
      Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group), person: @tg_member)
      @tg_extern = Fabricate(Role::External.name.to_sym, group: groups(:top_group)).person

      @bl_leader = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)).person
      @bl_extern = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one)).person

      @bg_leader = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)).person
      @bg_member = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one)).person
    end

    context "group" do
      it "loads all members of a group" do
        expect(entries.collect(&:id)).to match_array([user, @tg_member].collect(&:id))
      end

      it "loads all members of a group" do
        expect(entries.collect(&:id)).to match_array([user, @tg_member].collect(&:id))
      end

      it "contains all existing members" do
        expect(entries.size).to eq(list_filter.all_count)
      end

      context "expired roles" do
        it "includes member with active and expired role" do
          @tg_member.roles.first.update(end_on: 1.day.ago)
          expect(entries).to include(@tg_member)
        end

        it "includes member with only expired roles" do
          @tg_member.roles.update_all(end_on: 1.day.ago)
          expect(entries).not_to include(@tg_member)
        end
      end

      context "with external types" do
        let(:role_types) { [Role::External] }

        it "loads externs of a group" do
          expect(entries.collect(&:id)).to match_array([@tg_extern].collect(&:id))
        end

        it "contains all existing externals" do
          expect(entries.size).to eq(list_filter.all_count)
        end
      end

      context "with specific types" do
        let(:role_types) { [Role::External, Group::TopGroup::Member] }

        it "loads selected roles of a group" do
          expect(entries.collect(&:id)).to match_array([@tg_member, @tg_extern].collect(&:id))
        end

        it "contains all existing people" do
          expect(entries.size).to eq(list_filter.all_count)
        end
      end
    end

    context "layer" do
      let(:group) { groups(:bottom_layer_one) }
      let(:range) { "layer" }

      context "with layer and below full" do
        let(:user) { @bl_leader }

        it "loads people in layer when no types given" do
          expect(entries.collect(&:id)).to match_array([people(:bottom_member),
            @bl_leader,
            @bg_leader,
            @bg_member].collect(&:id))
          expect(list_filter.all_count).to eq(4)
        end

        context "with specific types" do
          let(:role_types) { [Group::BottomGroup::Member, Role::External] }

          it "loads selected roles of a group when types given" do
            expect(entries.collect(&:id)).to match_array([@bg_member, @bl_extern].collect(&:id))
            expect(list_filter.all_count).to eq(2)
          end
        end
      end
    end

    context "deep" do
      let(:group) { groups(:top_layer) }
      let(:range) { "deep" }

      it "loads people in subtree when no types are given" do
        expect(entries.collect(&:id)).to match_array([people(:top_leader),
          people(:bottom_member),
          @tg_member,
          @bl_leader,
          @bg_leader].collect(&:id))
        expect(list_filter.all_count).to eq(6)
      end

      context "with specific types" do
        let(:role_types) { [Group::BottomGroup::Leader, Role::External] }

        it "loads selected roles of a group when types given" do
          expect(entries.collect(&:id)).to match_array([@bg_leader, @tg_extern].collect(&:id))
        end

        it "contains not all existing people" do
          expect(entries.size).to eq(list_filter.all_count - 1)
        end
      end
    end
  end

  context "filtering specific timeframe" do
    let(:person) { people(:top_leader) }
    let(:today) { Date.current }

    def transform(attrs)
      attrs.slice(:start_at, :finish_at).transform_values do |value|
        value.to_date.to_s
      end
    end

    context :date_range do
      def date_range(attrs = {})
        Person::Filter::Role.new(:role, transform(attrs)).date_range
      end

      it "sets min to beginning_of_time if missing" do
        expect(date_range.min).to eq Time.zone.at(0).to_date
      end

      it "sets max to Date.today#end_of_day if missing" do
        expect(date_range.max).to eq today
      end

      it "sets min to start_at#beginning_of_day" do
        expect(date_range(start_at: today).min).to eq today
      end

      it "sets max to finish_at#end_of_day" do
        expect(date_range(finish_at: today).max).to eq today
      end

      it "accepts start_at and finish_at on same day" do
        range = date_range(start_at: today, finish_at: today)
        expect(range.min).to eq today
        expect(range.max).to eq today
      end

      it "min and max are nil if range is invalid" do
        range = date_range(start_at: today, finish_at: today.yesterday)
        expect(range.min).to be_nil
        expect(range.max).to be_nil
      end
    end

    context :filter do
      def filter(attrs)
        kind = attrs[:kind] || described_class.to_s
        include_archived = attrs[:include_archived]
        role_type_ids = Array(role_type).collect(&:id)
        filters = {role: transform(attrs).merge(role_type_ids: role_type_ids, kind: kind, include_archived: include_archived)}
        Person::Filter::List.new(attrs.fetch(:group, group), user, range: attrs.fetch(:range, range), filters: filters)
      end

      context :created do
        let(:role) { roles(:top_leader) }
        let(:role_type) { Group::TopGroup::Leader }

        it "finds role started on same day" do
          role.update_columns(start_on: today)
          expect(filter(start_at: today).entries).to have(1).item
        end

        it "finds role started within range" do
          role.update_columns(start_on: today)
          expect(filter(start_at: today, finish_at: today).entries).to have(1).item
        end

        it "does not find role started before start_at" do
          role.update!(start_on: 1.day.ago)
          expect(filter(start_at: today).entries).to be_empty
        end

        it "does not find role started after finish_at" do
          role.update_columns(start_on: 1.day.from_now)
          expect(filter(finish_at: today).entries).to be_empty
        end

        it "does not find role when invalid range is given" do
          role.update_columns(start_on: today, end_on: today)
          expect(filter(start_at: today, finish_at: 1.day.ago).entries).to be_empty
        end
      end

      context :deleted do
        let(:role_type) { Group::TopGroup::Member }
        let(:role) { person.roles.create!(type: role_type.sti_name, group: group) }

        it "finds role ended on same day" do
          role.update!(end_on: today)
          expect(filter(start_at: today).entries).to have(1).item
        end

        it "finds role ended within range" do
          role.update!(end_on: today)
          expect(filter(start_at: today, finish_at: today).entries).to have(1).item
        end

        it "does not find role ended before start_on" do
          role.update!(end_on: 1.day.ago)
          expect(filter(start_at: today).entries).to be_empty
        end

        it "does not find role ended after finish_at" do
          role.update!(end_on: 1.day.from_now)
          expect(filter(finish_at: today).entries).to be_empty
        end

        it "does not find role ended on same when invalid range is given" do
          role.update!(end_on: today)
          expect(filter(start_at: today, finish_at: 1.day.ago).entries).to be_empty
        end

        it "does not find active role" do
          role.update_columns(start_on: today)
          expect(filter(start_at: today).entries).to be_empty
        end

        it "does not find active role if ended role from other group matches" do
          other_group = Fabricate(Group::TopGroup.name.to_sym, parent: groups(:top_layer))
          other_role = Fabricate(Group::TopGroup::Member.name.to_sym, group: other_group, person: person)
          other_role.update!(end_on: today)
          expect(filter(start_at: today).entries).to be_empty
        end
      end

      context :without_role_type do
        let(:role_type) { nil }
        let(:role) { person.roles.create!(type: Group::TopGroup::Member.sti_name, group: group) }

        context :deleted do
          it "applies filter and does not find role ended outside of timeframe" do
            role.update!(end_on: 3.days.ago)
            expect(filter(start_at: today).entries).to be_empty
            expect(filter(start_at: today).all_count).to eq 0
          end

          it "applies filter and finds role ended inside of timeframe" do
            role.update!(end_on: today)
            expect(filter(start_at: today).entries).to have(1).item
            expect(filter(start_at: today).all_count).to eq 1
          end
        end
      end

      context :bottom_group_one_one do
        let(:group) { groups(:bottom_group_one_one) }
        let(:role_type) { Group::BottomGroup::Member }
        let(:role) { Fabricate(role_type.name.to_sym, group: group) }
        let(:user) { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)).person }

        context :deleted do
          it "finds single ended role and can show it on group" do
            role.update!(end_on: today)
            expect(filter(start_at: today).entries).to have(1).item
            expect(filter(start_at: today).all_count).to eq 1
          end

          it "finds single ended role and can show it with deep filter" do
            role.update!(end_on: today)
            expect(filter(range: "deep", group: group, start_at: today).entries).to have(1).item
            expect(filter(start_at: today).all_count).to eq 1
          end
        end
      end

      context :inactive do
        let!(:role) { roles(:top_leader).tap { |r| r.update!(start_on: 15.days.ago) } }
        let(:role_type) { Group::TopGroup::Leader }
        let(:other_role_type) { Group::TopGroup::Member }

        def entries(attrs = {})
          filter(attrs.merge(kind: "inactive")).entries
        end

        it "does not find active role" do
          expect(entries).to be_empty
        end

        # because time range applies for active and inactive conditions
        it "does not find active role when searching with earlier range" do
          start_on = role.start_on
          expect(entries(start_at: start_on - 1.year, finish_at: start_on - 1.day)).to be_empty
        end

        # filter in general requires an active role per person
        it "does not find only ended role" do
          role.update!(end_on: 10.days.ago)
          expect(entries(start_at: 1.day.ago)).to be_empty
        end

        it "does not find inactive role even when include_archived" do
          role.update!(end_on: 2.days.ago)
          expect(entries(start_at: 1.day.ago, finish_at: today, include_archived: true)).to be_empty
        end

        context "with other active role in group" do
          before { person.roles.create!(type: other_role_type.sti_name, group: group) }

          it "does find person ended before range" do
            role.update!(end_on: 2.days.ago)
            expect(entries(start_at: 1.day.ago, finish_at: today)).to have(1).item
          end

          it "does not find person ended within range" do
            role.update!(end_on: today)
            expect(entries(start_at: 1.day.ago, finish_at: 1.day.from_now)).to be_empty
          end

          it "does not find person ended after range" do
            role.update!(end_on: 2.days.from_now)
            expect(entries(start_at: 1.day.ago, finish_at: today)).to be_empty
          end

          it "does find person with empty range" do
            role.update!(end_on: 2.days.ago)
            expect(entries).to have(1).item
          end

          it "does find person with empty range if role never existed" do
            Role.where(id: role.id).delete_all
            expect(entries).to have(1).item
          end
        end

        context "with inactive and other role" do
          let!(:other_role) { person.roles.create!(type: other_role_type.sti_name, group: group) }

          it "finds person with inactive role ended before timeframe" do
            role.update!(start_on: 2.days.ago, end_on: 1.day.ago)
            expect(filter(kind: "inactive", start_at: today).entries).to have(1).item
          end

          it "does not find person with inactive role ended within range" do
            role.update!(end_on: today)
            expect(filter(kind: "inactive", start_at: today, finish_at: today).entries).to be_empty
          end

          it "does not find person with other role ended before timeframe" do
            other_role.update!(start_on: 2.days.ago, end_on: 1.day.ago)
            expect(filter(kind: "inactive", start_at: today).entries).to be_empty
          end

          it "does not find person with other role ended within range" do
            other_role.update!(end_on: today)
            expect(filter(kind: "inactive", start_at: today, finish_at: today).entries).to be_empty
          end

          it "does not find person with other role started within range" do
            other_role.update!(start_on: today)
            expect(filter(kind: "inactive", start_at: today, finish_at: today).entries).to be_empty
          end
        end

        context "with only other role" do
          before { role.update!(end_on: 10.days.ago) }

          let!(:other_role) { person.roles.create!(type: other_role_type.sti_name, group: group) }

          it "does not find person with other role ended before timeframe" do
            other_role.update!(end_on: 1.day.ago)
            expect(filter(kind: "inactive", start_at: today).entries).to be_empty
          end

          it "finds person with other role ending on last day of timeframe" do
            other_role.update!(end_on: today)
            expect(filter(kind: "inactive", start_at: today, finish_at: today).entries).to have(1).item
          end

          it "finds person with other role started within range" do
            other_role.update!(start_on: today)
            expect(filter(kind: "inactive", start_at: today, finish_at: today).entries).to have(1).item
          end

          it "does not find person with other role starting after timeframe" do
            other_role.update!(start_on: 1.day.from_now)
            expect(filter(kind: "inactive", end_on: today).entries).to be_empty
          end
        end
      end

      context :active do
        let(:role_type) { Group::TopGroup::Member }
        let(:role) { person.roles.create!(type: role_type.sti_name, group: group) }

        it "does not find role ended before timeframe" do
          role.update!(start_on: 2.days.ago, end_on: 1.day.ago)
          expect(filter(start_at: today).entries).to be_empty
        end

        it "finds role ended within range" do
          role.update!(end_on: today)
          expect(filter(start_at: today, finish_at: today).entries).to have(1).item
        end

        it "finds role started within range" do
          role.update!(start_on: today)
          expect(filter(start_at: today, finish_at: today).entries).to have(1).item
        end

        context "excluding archived" do
          context "within time range" do
            it "does not find archived role with past archived_at" do
              role.update_attribute(:archived_at, 1.day.ago)
              expect(filter(start_at: today, finish_at: today, include_archived: false).entries).to be_empty
            end

            it "finds archived role outside with future archived_at" do
              role.update_attribute(:archived_at, 1.day.from_now)
              expect(filter(start_at: today, finish_at: today, include_archived: false).entries).to have(1).item
            end
          end

          context "outside time range" do
            it "does not find archived role with past archived_at" do
              role.update!(start_on: 2.days.ago)
              role.update_attribute(:archived_at, 1.day.ago)
              expect(filter(start_at: today, kind: "created", include_archived: false).entries).to be_empty
            end

            it "does not find archived role outside with future archived_at" do
              role.update!(start_on: 2.days.ago)
              role.update_attribute(:archived_at, 1.day.from_now)
              expect(filter(start_at: today, kind: "created", include_archived: false).entries).to be_empty
            end
          end
        end

        context "including archived" do
          context "within time range" do
            it "finds role archived with past archived_at" do
              role.update_attribute(:archived_at, 1.day.ago)
              expect(filter(start_at: today, finish_at: today, include_archived: true).entries).to have(1).item
            end

            it "finds archived role with future archived_at" do
              role.update_attribute(:archived_at, 1.day.from_now)
              expect(filter(start_at: today, finish_at: today, include_archived: true).entries).to have(1).item
            end
          end

          context "outside time range" do
            it "does not find role archived with past archived_at" do
              role.update!(start_on: 2.days.ago)
              role.update_attribute(:archived_at, 1.day.ago)
              expect(filter(start_at: today, kind: "created", include_archived: true).entries).to be_empty
            end

            it "does not find archived role with future archived_at" do
              role.update!(start_on: 2.days.ago)
              role.update_attribute(:archived_at, 1.day.from_now)
              expect(filter(start_at: today, kind: "created", include_archived: true).entries).to be_empty
            end
          end
        end
      end
    end
  end
end
