# encoding: utf-8

#  Copyright (c) 2012-2017, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Person::Filter::Qualification do

  let(:user) { people(:top_leader) }
  let(:group) { groups(:top_layer) }
  let(:range) { nil }
  let(:validity) { "all" }
  let(:match) { "one" }
  let(:qualification_kind_ids) { [] }

  let(:list_filter) do
    Person::Filter::List.new(
      group,
      user,
      range: range,
      filters: { qualification: filters.merge(additional_filter_params) }
    )
  end

  let(:filters) do
    {
      qualification_kind_ids: qualification_kind_ids,
      validity: validity,
      match: match,
    }
  end
  let(:additional_filters) { {} }

  let(:entries) { list_filter.entries }

  let(:bl_leader) { create_person(Group::BottomLayer::Leader, :bottom_layer_one, "reactivateable", :sl, :gl_leader) }

  def additional_filter_params
    additional_filters.invert.stringify_keys.invert
  end

  def create_person(role, group, validity, *qualification_kinds)
    person = Fabricate(role.name.to_sym, group: groups(group)).person
    qualification_kinds.each do |key|
      kind = qualification_kinds(key)
      start = case validity
              when "active"         then Date.today
              when "reactivateable" then Date.today - kind.validity.years - 1.year
              when Fixnum           then Date.new(validity, 1, 1)
              else Date.today - 20.years
              end
      Fabricate(:qualification, person: person, qualification_kind: kind, start_at: start)
    end
    person
  end

  def create_qualification(person, kind, year)
    Fabricate(:qualification,
              person: person,
              qualification_kind: qualification_kinds(kind),
              start_at: Date.new(year, 1, 1))
  end

  context "initialize" do
    it "is not year_scope if params is empty" do
      expect(described_class.new(:qualification, {})).not_to be_year_scope
    end

    %w(start_at finish_at).product(%w(year_from year_until)).each do |pre, post|
      it "is year_scope if #{pre}_#{post} is present" do
        filter = described_class.new(:qualification, :"#{pre}_#{post}" => nil)
        expect(filter).not_to be_year_scope
      end

      it "is not year_scope if #{pre}_#{post} is present but blank" do
        filter = described_class.new(:qualification, :"#{pre}_#{post}" => 1)
        expect(filter).to be_year_scope
      end
    end
  end

  context "filtering" do

    before do
      @tg_member = create_person(Group::TopGroup::Member, :top_group, "active", :sl)
      # duplicate qualification
      Fabricate(:qualification, person: @tg_member, qualification_kind: qualification_kinds(:sl), start_at: Date.today - 2.weeks)

      @tg_extern = create_person(Role::External, :top_group, "active", :sl)

      @bl_leader = bl_leader
      @bl_extern = create_person(Role::External, :bottom_layer_one, "reactivateable", :gl_leader)

      @bg_leader = create_person(Group::BottomGroup::Leader, :bottom_group_one_one, "all", :sl, :ql)
      @bg_member = create_person(Group::BottomGroup::Member, :bottom_group_one_one, "active", :sl)
    end


    context "no filter" do
      it "loads only entries on group" do
        expect(entries).to be_empty
      end

      it "count is 0" do
        expect(list_filter.all_count).to eq(0)
      end
    end

    context "kind deep" do
      let(:range) { "deep" }

      context "no qualification kinds" do
        it "loads people in subtree" do
          expect(entries).to match_array([
            people(:top_leader),
            people(:bottom_member),
            @tg_member,
            @tg_extern,
            @bl_leader,
            @bg_leader
          ])
        end
      end

      context "with qualification kinds" do
        let(:qualification_kind_ids) { qualification_kinds(:sl, :gl_leader).collect(&:id) }

        it "loads all entries in layer and below" do
          expect(entries).to match_array([@tg_member, @tg_extern, @bl_leader, @bg_leader])
        end

        it "contains only visible people" do
          expect(entries.size).to eq(list_filter.all_count - 2)
        end

        context "with years" do
          let(:qualification_kind_ids) { [qualification_kinds(:sl_leader).id] }

          before do
            @sl_2013 = create_person(Group::TopGroup::Member, :top_group, 2013, :sl_leader)
            @sl_2014 = create_person(Group::TopGroup::Member, :top_group, 2014, :sl_leader)
            @sl_2015 = create_person(Group::TopGroup::Member, :top_group, 2015, :sl_leader)
            @sl_2016 = create_person(Group::TopGroup::Member, :top_group, 2016, :sl_leader)
          end

          context "loads entry with start_at later" do
            let(:additional_filters) do
              {
                start_at_year_from: 2015
              }
            end
            it "correctly" do
              expect(entries).to match_array([@sl_2015, @sl_2016])
            end

          end

          context "loads entry with start_at before" do
            let(:additional_filters) do
              {
                start_at_year_until: "2015"
              }
            end
            it "correctly" do
              expect(entries).to match_array([@sl_2015, @sl_2014, @sl_2013])
            end

            it "only considers newest qualification for query" do
              create_qualification(@sl_2015, :sl_leader, 2016)
              expect(entries).to match_array([@sl_2014, @sl_2013])
            end
          end

          context "loads entry with start_at between" do
            let(:additional_filters) do
              {
                start_at_year_from: 2014,
                start_at_year_until: 2015
              }
            end
            it "correctly" do
              expect(entries).to match_array([@sl_2015, @sl_2014])
            end
          end

          context "loads entry with finish_at later" do
            let(:additional_filters) do
              {
                finish_at_year_from: 2016
              }
            end
            it "correctly" do
              expect(entries).to match_array([@sl_2014, @sl_2015, @sl_2016])
            end
          end

          context "loads entry with finish_at before" do
            let(:additional_filters) do
              {
                finish_at_year_until: 2016
              }
            end
            it "correctly" do
              expect(entries).to match_array([@sl_2014, @sl_2013])
            end
          end

          context "loads entry with finish_at between" do
            let(:additional_filters) do
              {
                finish_at_year_from: 2016,
                finish_at_year_until: 2017
              }
            end
            it "correctly" do
              expect(entries).to match_array([@sl_2015, @sl_2014])
            end
          end

          context "only active" do

            context "loads entry with finish_at before" do
              let(:additional_filters) do
                {
                  validity: "active",
                  finish_at_year_until: 2016
                }
              end
              it "correctly" do
                expect(entries).to match_array([])
              end
            end

          end
        end

        context "as bottom leader" do
          let(:user) { bl_leader }

          it "loads all accessible entries" do
            expect(entries).to match_array([@bl_leader, @bg_leader, @bg_member, @bl_extern])
          end

          it "contains only visible people" do
            expect(entries.size).to eq(list_filter.all_count - 2)
          end

          context "combined with role filter" do
            let(:list_filter) do
              Person::Filter::List.new(group,
                                       user,
                                       range: range,
                                       filters: {
                                         role: {
                                           role_types: [
                                             Group::TopGroup::Member.sti_name,
                                             Group::BottomLayer::Leader.sti_name,
                                             Group::BottomGroup::Leader.sti_name
                                           ]
                                         },
                                         qualification: {
                                           qualification_kind_ids: qualification_kind_ids,
                                           validity: validity
                                         }
                                       })
            end

            it "loads all accessible entries" do
              expect(entries).to match_array([@bl_leader, @bg_leader])
            end

            it "contains only visible people" do
              expect(entries.size).to eq(list_filter.all_count - 1)
            end

          end
        end
      end

    end

    context "kind layer" do
      let(:range) { "layer" }

      context "with qualification kinds" do
        let(:qualification_kind_ids) { qualification_kinds(:sl, :gl_leader).collect(&:id) }

        it "loads all entries in layer" do
          expect(entries).to match_array([@tg_member, @tg_extern])
        end

        it "contains all people" do
          expect(entries.size).to eq(list_filter.all_count)
        end
      end
    end

    context "in bottom layer" do
      let(:user) { bl_leader }
      let(:range) { "layer" }
      let(:group) { groups(:bottom_layer_one) }
      let(:qualification_kind_ids) { qualification_kinds(:sl, :gl_leader).collect(&:id) }

      context "active validities" do

        let(:validity) { "active" }

        it "loads matched entries" do
          expect(entries).to match_array([@bg_member])
        end

        it "contains all people" do
          expect(entries.size).to eq(list_filter.all_count)
        end

        context "with infinite qualifications" do
          let(:qualification_kind_ids) { qualification_kinds(:sl, :ql).collect(&:id) }

          it "contains them" do
            expect(entries).to match_array([@bg_member, @bg_leader])
          end
        end

        context "match all" do
          let(:match) { "all" }
          let(:qualification_kind_ids) { qualification_kinds(:sl, :ql).collect(&:id) }

          it "contains only people with all qualifications" do
            Fabricate(:qualification,
                      person: @bg_leader,
                      qualification_kind: qualification_kinds(:sl),
                      start_at: Date.today)

            expect(entries).to match_array([@bg_leader])
          end

          it "contains people with additional qualifications" do
            Fabricate(:qualification,
                      person: @bg_leader,
                      qualification_kind: qualification_kinds(:sl),
                      start_at: Date.today)
            Fabricate(:qualification,
                      person: @bg_leader,
                      qualification_kind: qualification_kinds(:gl_leader),
                      start_at: Date.today)

            expect(entries).to match_array([@bg_leader])
          end

          context "loads entry with start_at between" do
            let(:start_at) { Date.today - 2.years }
            let(:additional_filters) do
              {
                start_at_year_from: start_at.year,
                start_at_year_until: start_at.year
              }
            end

            it "correctly" do
              @bg_leader.qualifications.
                find { |q| q.qualification_kind == qualification_kinds(:ql) }.
                update!(start_at: start_at)
              Fabricate(:qualification,
                        person: @bg_leader,
                        qualification_kind: qualification_kinds(:sl),
                        start_at: start_at)

              expect(entries).to match_array([@bg_leader])
            end
          end

          context "does not contain entries outside start_at between" do
            let(:start_at) { Date.today - 2.years }
            let(:additional_filters) do
              {
                start_at_year_from: start_at.year - 2,
                start_at_year_until: start_at.year - 1
              }
            end

            it "correctly" do
              @bg_leader.qualifications.
                find { |q| q.qualification_kind == qualification_kinds(:ql) }.
                update!(start_at: start_at)
              Fabricate(:qualification,
                        person: @bg_leader,
                        qualification_kind: qualification_kinds(:sl),
                        start_at: start_at)

              expect(entries).to match_array([])
            end
          end

          it "does not contain people with all, but expired qualifications" do
            expect(entries).to match_array([])
          end

        end

        context "as top leader" do
          let(:user) { people(:top_leader) }

          it "does not load non-visible entries" do
            expect(entries).to match_array([])
          end

          it "contains only visible people" do
            expect(entries.size).to eq(list_filter.all_count - 1)
          end
        end
      end

      context "reactivateable validities" do
        let(:validity) { "reactivateable" }

        it "loads matched entries" do
          expect(entries).to match_array([@bg_member, @bl_extern, @bl_leader])
        end

        it "contains all people" do
          expect(entries.size).to eq(list_filter.all_count)
        end

        context "with infinite qualifications" do
          let(:qualification_kind_ids) { qualification_kinds(:sl, :ql).collect(&:id) }
          it "contains them" do
            expect(entries).to match_array([@bg_member, @bg_leader])
          end
        end

        context "match all" do
          let(:match) { "all" }

          before { qualification_kinds(:sl).update!(reactivateable: 2) }

          it "loads matched entries" do
            expect(entries).to match_array([@bl_leader])
          end

          it "loads matched entries with multiple, old qualifications just once" do
            kind = qualification_kinds(:sl)
            Fabricate(:qualification,
                      person: @bg_member,
                      qualification_kind: kind,
                      start_at: Date.today - kind.validity.years - 1.year)
            kind = qualification_kinds(:gl_leader)
            Fabricate(:qualification,
                      person: @bg_member,
                      qualification_kind: kind,
                      start_at: Date.today - kind.validity.years - 1.year)

            expect(entries).to match_array([@bg_member, @bl_leader])
          end

          it "does not contain people with all, but expired qualifications" do
            Fabricate(:qualification,
                      person: @bg_member,
                      qualification_kind: qualification_kinds(:gl_leader),
                      start_at: Date.today - 10.years)

            expect(entries).to match_array([@bl_leader])
          end
        end
      end

      context "all validities" do
        let(:validity) { "all" }

        it "loads matched entries" do
          expect(entries).to match_array([@bg_member, @bl_extern, @bg_leader, @bl_leader])
        end

        it "contains all people" do
          expect(entries.size).to eq(list_filter.all_count)
        end

        context "match all" do
          let(:match) { "all" }

          it "loads matched entries with multiple, old qualifications just once" do
            kind = qualification_kinds(:sl)
            Fabricate(:qualification,
                      person: @bg_member,
                      qualification_kind: kind,
                      start_at: Date.today - kind.validity.years - 1.year)
            Fabricate(:qualification,
                      person: @bg_member,
                      qualification_kind: qualification_kinds(:gl_leader),
                      start_at: Date.today - 10.years)

            expect(entries).to match_array([@bg_member, @bl_leader])
          end
        end
      end
    end

    it "does not fail if sorting by role and person has only group_read" do
      allow(Settings.people).to receive(:default_sort).and_return("role")
      list_filter = Person::Filter::List.new(
        group,
        create_person(Group::BottomGroup::Member, :bottom_group_one_one, "active"),
        range: "214",
        filters: { qualification: { qualification_kind_ids: "2", validity: "1" }}
      )
      expect(list_filter.entries).to be_empty
    end

    it "does not fail if sorting by role and person has layer_and_below_full" do
      allow(Settings.people).to receive(:default_sort).and_return("role")
      list_filter = Person::Filter::List.new(
        group,
        user,
        range: "214",
        filters: { qualification: { qualification_kind_ids: "2", validity: "1" }}
      )
      expect(list_filter.entries).to be_empty
    end

  end
end
