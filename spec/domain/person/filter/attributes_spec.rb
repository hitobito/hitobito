#  Copyright (c) 2012-2024, Schweizer Blasmusikverband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Person::Filter::Attributes do
  let(:user) { people(:top_leader) }
  let(:group) { groups(:top_group) }
  let(:key) { "" }
  let(:constraint) { "match" }
  let(:value) { "" }
  let(:range) { "deep" }

  let(:list_filter) do
    Person::Filter::List.new(
      group,
      user,
      range: range,
      filters: {attributes: filters.merge(additional_filters)}
    )
  end

  let(:filters) do
    {
      "1234567890123": {
        key: key,
        constraint: constraint,
        value: value
      }
    }
  end

  let(:additional_filters) { {} }

  let(:entries) { list_filter.entries }

  context "filtering" do
    before do
      @tg_member1 = Fabricate(:person, first_name: "test1", last_name: "same", birthday: 27.years.ago, language: :en)
      Fabricate(Group::TopGroup::Member.name.to_sym, group: group, person: @tg_member1)

      @tg_member2 = Fabricate(:person, first_name: "test2", last_name: "same", birthday: 30.years.ago, language: :de)
      Fabricate(Group::TopGroup::Member.name.to_sym, group: group, person: @tg_member2)

      @tg_member3 = Fabricate(:person, first_name: "test3", last_name: "test3", birthday: 47.years.ago, language: :fr)
      Fabricate(Group::TopGroup::Member.name.to_sym, group: group, person: @tg_member3)
    end

    context "no filter" do
      it "contains all existing members" do
        expect(entries.size).to eq(list_filter.all_count)
      end
    end

    context "unknown attribute" do
      let(:key) { "unknonw" }

      it "contains all existing members" do
        expect(entries.size).to eq(list_filter.all_count)
      end
    end

    context "escaped value" do
      let(:key) { "address" }
      let(:value) { "'INJECTION" }

      it "does not cause sql injection" do
        expect { entries.size }.not_to raise_exception
      end
    end

    context "persisted attribute" do
      context "string attributes" do
        let(:key) { "first_name" }

        context "equal" do
          let(:constraint) { "equal" }

          context do
            let(:value) { "test1" }

            it "returns people with exact attribute" do
              expect(entries.size).to eq(1)
              expect(entries.first).to eq(@tg_member1)
            end
          end

          context do
            let(:value) { "test" }

            it "returns nobody if no exact attribute" do
              expect(entries.size).to be_zero
            end
          end
        end

        context "match" do
          let(:constraint) { "match" }
          let(:value) { "test" }

          it "returns people with matching attribute" do
            expect(entries.size).to eq(3)
            expect(entries).to include(@tg_member1)
            expect(entries).to include(@tg_member2)
            expect(entries).to include(@tg_member3)
          end
        end

        context "not_match" do
          let(:key) { "last_name" }
          let(:constraint) { "not_match" }
          let(:value) { "sam" }

          it "returns people with not matching attribute" do
            expect(entries).not_to include(@tg_member1)
            expect(entries).not_to include(@tg_member2)
            expect(entries).to include(@tg_member3)
          end
        end

        context "blank" do
          let(:key) { "last_name" }
          let(:constraint) { "blank" }
          let(:value) { nil }

          it "returns people with blank attribute" do
            @tg_member1.update!(last_name: "")
            @tg_member2.update!(last_name: nil)
            expect(entries).to include(@tg_member1)
            expect(entries).to include(@tg_member2)
            expect(entries).not_to include(@tg_member3)
          end
        end
      end

      context "email attributes" do
        let(:key) { "email" }

        context "equal" do
          let(:constraint) { "equal" }

          context "lowercase" do
            let(:value) { @tg_member1.email.to_s.downcase }

            it "returns people with exact attribute" do
              expect(entries.size).to eq(1)
              expect(entries.first).to eq(@tg_member1)
            end
          end

          context "uppercase" do
            let(:value) { @tg_member1.email.to_s.upcase }

            it "returns people with exact attribute" do
              expect(entries.size).to eq(1)
              expect(entries.first).to eq(@tg_member1)
            end
          end

          context do
            let(:value) { "test" }

            it "returns nobody if no exact attribute" do
              expect(entries.size).to be_zero
            end
          end
        end

        context "match" do
          let(:constraint) { "match" }
          let(:value) { "test" }

          it "returns people with matching attribute" do
            expect(entries.size).to eq(3)
            expect(entries).to include(@tg_member1)
            expect(entries).to include(@tg_member2)
            expect(entries).to include(@tg_member3)
          end
        end

        context "not_match" do
          let(:key) { "last_name" }
          let(:constraint) { "not_match" }
          let(:value) { "sam" }

          it "returns people with not matching attribute" do
            expect(entries).not_to include(@tg_member1)
            expect(entries).not_to include(@tg_member2)
            expect(entries).to include(@tg_member3)
          end
        end
      end

      context "integer attributes" do
        let(:key) { "id" }

        before do
          expect(Person).to receive(:filter_attrs).twice.and_return(id: {type: :integer})
        end

        context do
          let(:value) { @tg_member1.id }

          it "returns people with exact attribute" do
            expect(entries.size).to eq(1)
            expect(entries.first).to eq(@tg_member1)
          end
        end

        context do
          let(:value) { -1 }

          it "returns nobody if no matching attribute" do
            expect(entries.size).to be_zero
          end
        end

        context "smaller" do
          let(:constraint) { "smaller" }
          let(:value) { people(:bottom_member).id }

          it "returns people with matching attribute" do
            expect(entries).not_to include(user)
          end
        end

        context "greater" do
          let(:constraint) { "greater" }
          let(:value) { people(:bottom_member).id }

          it "returns people with matching attribute" do
            expect(entries).to include(user)
          end
        end
      end
    end

    context "years calculated attribute" do
      let(:key) { "years" }

      context "equal" do
        let(:constraint) { "equal" }

        context do
          let(:value) { "27" }

          it "returns people with exact attribute" do
            expect(entries.size).to eq(1)
            expect(entries.first).to eq(@tg_member1)
          end
        end

        context do
          let(:value) { "55" }

          it "returns nobody if no exact attribute" do
            expect(entries.size).to be_zero
          end
        end
      end

      context "smaller" do
        let(:constraint) { "smaller" }
        let(:value) { 32 }

        it "returns people with matching attribute" do
          expect(entries.size).to eq(2)
          expect(entries).to include(@tg_member1)
          expect(entries).to include(@tg_member2)
        end
      end

      context "greater" do
        let(:constraint) { "greater" }
        let(:value) { 32 }

        it "returns people with matching attribute" do
          expect(entries.size).to eq(1)
          expect(entries).to include(@tg_member3)
        end
      end
    end

    context "birthday date attribute" do
      let(:key) { "birthday" }

      context "equal" do
        let(:constraint) { "equal" }

        context do
          let(:value) { 27.years.ago.to_date.to_s }

          it "returns people with exact attribute" do
            expect(entries.size).to eq(1)
            expect(entries.first).to eq(@tg_member1)
          end
        end

        context do
          let(:value) { 55.years.ago.to_date.to_s }

          it "returns nobody if no exact attribute" do
            expect(entries.size).to be_zero
          end
        end
      end

      context "smaller" do
        let(:constraint) { "smaller" }
        let(:value) { 32.years.ago.to_date.to_s }

        it "returns people with matching attribute" do
          expect(entries.size).to eq(1)
          expect(entries).to include(@tg_member3)
        end
      end

      context "greater" do
        let(:constraint) { "greater" }
        let(:value) { 32.years.ago.to_date.to_s }

        it "returns people with matching attribute" do
          expect(entries.size).to eq(2)
          expect(entries).to include(@tg_member1)
          expect(entries).to include(@tg_member2)
        end
      end
    end

    context "unpersisted attribute" do
      let(:key) { "coolness_factor" }

      before do
        expect(Person).to receive(:filter_attrs).twice.and_return(coolness_factor: {type: :integer})
        allow_any_instance_of(Person).to receive(:coolness_factor) do |person|
          case person.first_name
          when "test1" then 27
          when "test2" then 30
          when "test3" then 47
          end
        end
      end

      context "equal" do
        let(:constraint) { "equal" }

        context do
          let(:value) { "27" }

          it "returns people with exact attribute" do
            expect(entries.size).to eq(1)
            expect(entries.first).to eq(@tg_member1)
          end
        end

        context do
          let(:value) { "55" }

          it "returns nobody if no exact attribute" do
            expect(entries.size).to be_zero
          end
        end
      end

      context "match" do
        let(:constraint) { "match" }
        let(:value) { "7" }

        it "returns people with matching attribute" do
          expect(entries.size).to eq(2)
          expect(entries).to include(@tg_member1)
          expect(entries).to include(@tg_member3)
        end
      end

      context "not_match" do
        let(:constraint) { "not_match" }
        let(:value) { "7" }

        it "returns people without matching attribute" do
          expect(entries).to include(@tg_member2)
          expect(entries).not_to include(@tg_member1)
          expect(entries).not_to include(@tg_member3)
        end
      end

      context "smaller" do
        let(:constraint) { "smaller" }
        let(:value) { 32 }

        it "returns people with matching attribute" do
          expect(entries.size).to eq(2)
          expect(entries).to include(@tg_member1)
          expect(entries).to include(@tg_member2)
        end
      end

      context "greater" do
        let(:constraint) { "greater" }
        let(:value) { 32 }

        it "returns people with matching attribute" do
          expect(entries.size).to eq(1)
          expect(entries).to include(@tg_member3)
        end
      end

      context "blank" do
        let(:constraint) { "blank" }

        it "returns people with matching attribute" do
          allow_any_instance_of(Person).to receive(:coolness_factor) do |person|
            case person.first_name
            when user.first_name then ""
            when "test1" then nil
            else 27
            end
          end
          expect(entries.size).to eq(2)
          expect(entries).to include(user)
          expect(entries).to include(@tg_member1)
          expect(entries).not_to include(@tg_member2)
        end
      end
    end

    context "multiple attributes" do
      let(:key) { "last_name" }
      let(:additional_filters) do
        {
          "2234567890123": {
            key: "first_name",
            constraint: "match",
            value: "test"
          }
        }
      end

      context "fulfilled" do
        context "match" do
          let(:constraint) { "match" }
          let(:value) { "sam" }

          it "returns all where both attributes are matching" do
            expect(entries.size).to eq(2)
            expect(entries).to include(@tg_member1)
            expect(entries).to include(@tg_member2)
          end
        end

        context "not_match" do
          let(:constraint) { "not_match" }
          let(:value) { "sam" }

          it "returns all where both attributes are matching" do
            expect(entries.size).to eq(1)
            expect(entries).to include(@tg_member3)
          end
        end

        context "equal" do
          let(:constraint) { "equal" }
          let(:value) { "test3" }

          it "returns all where booth attributes are matching" do
            expect(entries.size).to eq(1)
            expect(entries).to include(@tg_member3)
          end
        end
      end

      context "unfulfilled" do
        context "match" do
          let(:constraint) { "match" }
          let(:value) { "cz" }

          it "returns nobody if not both are matching" do
            expect(entries.size).to be_zero
          end
        end

        context "not_match" do
          let(:constraint) { "not_match" }
          let(:value) { "e" }

          it "returns nobody if not both are matching" do
            expect(entries.size).to eq 0
          end
        end
      end
    end
  end
end
