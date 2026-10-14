# frozen_string_literal: true

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Calendars::Events do
  before(:all) do
    @subgroup_event_types = Group::BottomGroup.event_types.clone
    Group::BottomGroup.event_types = [Event, Event::Course]
  end

  after(:all) do
    Group::BottomGroup.event_types = @subgroup_event_types
  end

  let(:layer) { groups(:bottom_layer_one) }
  let(:subgroup) { groups(:bottom_group_one_one) }
  let(:subsubgroup) { groups(:bottom_group_one_one_one) }

  let_it_be(:layer_event, reload: true) { Fabricate(:event, groups: [groups(:bottom_layer_one)]) }
  let_it_be(:layer_course, reload: true) { Fabricate(:course, groups: [groups(:bottom_layer_one)]) }
  let_it_be(:subgroup_event, reload: true) { Fabricate(:event, groups: [groups(:bottom_group_one_one)]) }
  let_it_be(:subgroup_course, reload: true) { Fabricate(:course, groups: [groups(:bottom_group_one_one)]) }
  let_it_be(:subsubgroup_event, reload: true) { Fabricate(:event, groups: [groups(:bottom_group_one_one_one)]) }
  let_it_be(:subsubgroup_course, reload: true) { Fabricate(:course, groups: [groups(:bottom_group_one_one_one)]) }

  let(:calendar) { Fabricate(:calendar, group: layer) }

  subject { Calendars::Events.new(calendar).events }

  def expect_events(included:, excluded:)
    found = subject.to_a
    found_names = (included + excluded).select { |name| found.include?(send(name)) }
    expect(found_names).to match_array(included)
  end

  context "with included calendar group" do
    context "layer" do
      let!(:calendar_group) { calendar.included_calendar_groups.first.tap { |g| g.update(group: layer) } }

      context "including all event types" do
        before { calendar_group.update(event_type: nil) }

        context "without subgroups" do
          before { calendar_group.update(with_subgroups: false) }

          it "includes only layer_event, layer_course" do
            expect_events(
              included: %i[layer_event layer_course],
              excluded: %i[subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
            )
          end

          context "with excluded calendar group" do
            let(:excluded_calendar_group) { Fabricate(:calendar_group, excluded: true, calendar: calendar) }

            context "layer" do
              before { excluded_calendar_group.update(group: layer) }

              context "excluding all event types" do
                before { excluded_calendar_group.update(event_type: nil) }

                context "excluding also subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end
              end

              context "excluding only plain events" do
                before { excluded_calendar_group.update(event_type: Event.name) }

                context "excluding also subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes only layer_course" do
                    expect_events(
                      included: %i[layer_course],
                      excluded: %i[layer_event subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only layer_course" do
                    expect_events(
                      included: %i[layer_course],
                      excluded: %i[layer_event subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end
              end

              context "excluding only courses" do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                context "excluding also subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes only layer_event" do
                    expect_events(
                      included: %i[layer_event],
                      excluded: %i[layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only layer_event" do
                    expect_events(
                      included: %i[layer_event],
                      excluded: %i[layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end
              end
            end

            context "subgroup makes no difference" do
              before { excluded_calendar_group.update(group: subgroup, event_type: nil, with_subgroups: true) }

              it "includes only layer_event, layer_course" do
                expect_events(
                  included: %i[layer_event layer_course],
                  excluded: %i[subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                )
              end
            end
          end
        end

        context "with subgroups" do
          before { calendar_group.update(with_subgroups: true) }

          it "includes only layer_event, layer_course, subgroup_event, subgroup_course, subsubgroup_event, subsubgroup_course" do
            expect_events(
              included: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course],
              excluded: []
            )
          end

          context "with excluded calendar group" do
            let(:excluded_calendar_group) { Fabricate(:calendar_group, excluded: true, calendar: calendar) }

            context "layer" do
              before { excluded_calendar_group.update(group: layer) }

              context "excluding all event types" do
                before { excluded_calendar_group.update(event_type: nil) }

                context "excluding also subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only subgroup_event, subgroup_course, subsubgroup_event, subsubgroup_course" do
                    expect_events(
                      included: %i[subgroup_event subgroup_course subsubgroup_event subsubgroup_course],
                      excluded: %i[layer_event layer_course]
                    )
                  end
                end
              end

              context "excluding only plain events" do
                before { excluded_calendar_group.update(event_type: Event.name) }

                context "excluding also subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes only layer_course, subgroup_course, subsubgroup_course" do
                    expect_events(
                      included: %i[layer_course subgroup_course subsubgroup_course],
                      excluded: %i[layer_event subgroup_event subsubgroup_event]
                    )
                  end
                end

                context "not excluding subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only layer_course, subgroup_event, subgroup_course, subsubgroup_event, subsubgroup_course" do
                    expect_events(
                      included: %i[layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course],
                      excluded: %i[layer_event]
                    )
                  end
                end
              end

              context "excluding only courses" do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                context "excluding also subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes only layer_event, subgroup_event, subsubgroup_event" do
                    expect_events(
                      included: %i[layer_event subgroup_event subsubgroup_event],
                      excluded: %i[layer_course subgroup_course subsubgroup_course]
                    )
                  end
                end

                context "not excluding subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only layer_event, subgroup_event, subgroup_course, subsubgroup_event, subsubgroup_course" do
                    expect_events(
                      included: %i[layer_event subgroup_event subgroup_course subsubgroup_event subsubgroup_course],
                      excluded: %i[layer_course]
                    )
                  end
                end
              end
            end

            context "subgroup" do
              before { excluded_calendar_group.update(group: subgroup) }

              context "excluding all event types" do
                before { excluded_calendar_group.update(event_type: nil) }

                context "excluding also subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes only layer_event, layer_course" do
                    expect_events(
                      included: %i[layer_event layer_course],
                      excluded: %i[subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only layer_event, layer_course, subsubgroup_event, subsubgroup_course" do
                    expect_events(
                      included: %i[layer_event layer_course subsubgroup_event subsubgroup_course],
                      excluded: %i[subgroup_event subgroup_course]
                    )
                  end
                end
              end

              context "excluding only plain events" do
                before { excluded_calendar_group.update(event_type: Event.name) }

                context "excluding also subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes only layer_event, layer_course, subgroup_course, subsubgroup_course" do
                    expect_events(
                      included: %i[layer_event layer_course subgroup_course subsubgroup_course],
                      excluded: %i[subgroup_event subsubgroup_event]
                    )
                  end
                end

                context "not excluding subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only layer_event, layer_course, subgroup_course, subsubgroup_event, subsubgroup_course" do
                    expect_events(
                      included: %i[layer_event layer_course subgroup_course subsubgroup_event subsubgroup_course],
                      excluded: %i[subgroup_event]
                    )
                  end
                end
              end

              context "excluding only courses" do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                context "excluding also subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes only layer_event, layer_course, subgroup_event, subsubgroup_event" do
                    expect_events(
                      included: %i[layer_event layer_course subgroup_event subsubgroup_event],
                      excluded: %i[subgroup_course subsubgroup_course]
                    )
                  end
                end

                context "not excluding subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only layer_event, layer_course, subgroup_event, subsubgroup_event, subsubgroup_course" do
                    expect_events(
                      included: %i[layer_event layer_course subgroup_event subsubgroup_event subsubgroup_course],
                      excluded: %i[subgroup_course]
                    )
                  end
                end
              end
            end
          end

          context "" do
            let(:tag_hello) { ActsAsTaggableOn::Tag.find_by(name: "hello") }
            let(:tag_world) { ActsAsTaggableOn::Tag.find_by(name: "world") }

            before do
              layer_event.update!(tag_list: "hello, world")
              layer_course.update!(tag_list: "foo")
              subgroup_event.update!(tag_list: "world, foo")
              subgroup_course.update!(tag_list: "hello, foo")
              subsubgroup_event.update!(tag_list: "")
              subsubgroup_course.update!(tag_list: "hello")
            end

            context "filtering by a single tag" do
              let!(:included_tag_hello) {
                Fabricate(:calendar_tag, excluded: false, calendar: calendar, tag: tag_hello)
              }

              it "includes only layer_event, subgroup_course, subsubgroup_course" do
                expect_events(
                  included: %i[layer_event subgroup_course subsubgroup_course],
                  excluded: %i[layer_course subgroup_event subsubgroup_event]
                )
              end
            end

            context "filtering by multiple tags includes all events containing any of the tags" do
              let!(:included_tag_hello) {
                Fabricate(:calendar_tag, excluded: false, calendar: calendar, tag: tag_hello)
              }
              let!(:included_tag_world) {
                Fabricate(:calendar_tag, excluded: false, calendar: calendar, tag: tag_world)
              }

              it "includes only layer_event, subgroup_event, subgroup_course, subsubgroup_course" do
                expect_events(
                  included: %i[layer_event subgroup_event subgroup_course subsubgroup_course],
                  excluded: %i[layer_course subsubgroup_event]
                )
              end
            end

            context "excluding a single tag" do
              let!(:excluded_tag_hello) { Fabricate(:calendar_tag, excluded: true, calendar: calendar, tag: tag_hello) }

              it "includes only layer_course, subgroup_event, subsubgroup_event" do
                expect_events(
                  included: %i[layer_course subgroup_event subsubgroup_event],
                  excluded: %i[layer_event subgroup_course subsubgroup_course]
                )
              end
            end

            context "excluding multiple tags leaves only events containing none of the tags" do
              let!(:excluded_tag_hello) { Fabricate(:calendar_tag, excluded: true, calendar: calendar, tag: tag_hello) }
              let!(:excluded_tag_world) { Fabricate(:calendar_tag, excluded: true, calendar: calendar, tag: tag_world) }

              it "includes only layer_course, subsubgroup_event" do
                expect_events(
                  included: %i[layer_course subsubgroup_event],
                  excluded: %i[layer_event subgroup_event subgroup_course subsubgroup_course]
                )
              end
            end

            context "including and excluding some tags, excluding takes precedence" do
              let!(:included_tag_hello) {
                Fabricate(:calendar_tag, excluded: false, calendar: calendar, tag: tag_hello)
              }
              let!(:excluded_tag_world) { Fabricate(:calendar_tag, excluded: true, calendar: calendar, tag: tag_world) }

              it "includes only subgroup_course, subsubgroup_course" do
                expect_events(
                  included: %i[subgroup_course subsubgroup_course],
                  excluded: %i[layer_event layer_course subgroup_event subsubgroup_event]
                )
              end
            end
          end
        end
      end

      context "including only plain events" do
        before { calendar_group.update(event_type: Event.name) }

        context "without subgroups" do
          before do
            calendar_group.update(with_subgroups: false)
          end

          it "includes only layer_event" do
            expect_events(
              included: %i[layer_event],
              excluded: %i[layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
            )
          end

          context "with excluded calendar group" do
            let(:excluded_calendar_group) { Fabricate(:calendar_group, excluded: true, calendar: calendar) }

            context "layer" do
              before { excluded_calendar_group.update(group: layer) }

              context "excluding all event types" do
                before { excluded_calendar_group.update(event_type: nil) }

                context "excluding also subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end
              end

              context "excluding only plain events" do
                before { excluded_calendar_group.update(event_type: Event.name) }

                context "excluding also subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end
              end

              context "excluding only courses makes no difference" do
                before { excluded_calendar_group.update(event_type: Event::Course.name, with_subgroups: true) }

                it "includes only layer_event" do
                  expect_events(
                    included: %i[layer_event],
                    excluded: %i[layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                  )
                end
              end
            end

            context "subgroup makes no difference" do
              before { excluded_calendar_group.update(group: subgroup, event_type: nil, with_subgroups: true) }

              it "includes only layer_event" do
                expect_events(
                  included: %i[layer_event],
                  excluded: %i[layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                )
              end
            end
          end
        end

        context "with subgroups" do
          before { calendar_group.update(with_subgroups: true) }

          it "includes only layer_event, subgroup_event, subsubgroup_event" do
            expect_events(
              included: %i[layer_event subgroup_event subsubgroup_event],
              excluded: %i[layer_course subgroup_course subsubgroup_course]
            )
          end

          context "with excluded calendar group" do
            let(:excluded_calendar_group) { Fabricate(:calendar_group, excluded: true, calendar: calendar) }

            context "layer" do
              before { excluded_calendar_group.update(group: layer) }

              context "excluding all event types" do
                before { excluded_calendar_group.update(event_type: nil) }

                context "excluding also subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only subgroup_event, subsubgroup_event" do
                    expect_events(
                      included: %i[subgroup_event subsubgroup_event],
                      excluded: %i[layer_event layer_course subgroup_course subsubgroup_course]
                    )
                  end
                end
              end

              context "excluding only plain events" do
                before { excluded_calendar_group.update(event_type: Event.name) }

                context "excluding also subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only subgroup_event, subsubgroup_event" do
                    expect_events(
                      included: %i[subgroup_event subsubgroup_event],
                      excluded: %i[layer_event layer_course subgroup_course subsubgroup_course]
                    )
                  end
                end
              end

              context "excluding only courses" do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                context "excluding also subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes only layer_event, subgroup_event, subsubgroup_event" do
                    expect_events(
                      included: %i[layer_event subgroup_event subsubgroup_event],
                      excluded: %i[layer_course subgroup_course subsubgroup_course]
                    )
                  end
                end

                context "not excluding subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only layer_event, subgroup_event, subsubgroup_event" do
                    expect_events(
                      included: %i[layer_event subgroup_event subsubgroup_event],
                      excluded: %i[layer_course subgroup_course subsubgroup_course]
                    )
                  end
                end
              end
            end

            context "subgroup" do
              before { excluded_calendar_group.update(group: subgroup) }

              context "excluding all event types" do
                before { excluded_calendar_group.update(event_type: nil) }

                context "excluding also subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes only layer_event" do
                    expect_events(
                      included: %i[layer_event],
                      excluded: %i[layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only layer_event, subsubgroup_event" do
                    expect_events(
                      included: %i[layer_event subsubgroup_event],
                      excluded: %i[layer_course subgroup_event subgroup_course subsubgroup_course]
                    )
                  end
                end
              end

              context "excluding only plain events" do
                before { excluded_calendar_group.update(event_type: Event.name) }

                context "excluding also subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes only layer_event" do
                    expect_events(
                      included: %i[layer_event],
                      excluded: %i[layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only layer_event, subsubgroup_event" do
                    expect_events(
                      included: %i[layer_event subsubgroup_event],
                      excluded: %i[layer_course subgroup_event subgroup_course subsubgroup_course]
                    )
                  end
                end
              end

              context "excluding only courses makes no difference" do
                before { excluded_calendar_group.update(event_type: Event::Course.name, with_subgroups: true) }

                it "includes only layer_event, subgroup_event, subsubgroup_event" do
                  expect_events(
                    included: %i[layer_event subgroup_event subsubgroup_event],
                    excluded: %i[layer_course subgroup_course subsubgroup_course]
                  )
                end
              end
            end
          end
        end
      end

      context "including only courses" do
        before { calendar_group.update(event_type: Event::Course.name) }

        context "without subgroups" do
          before { calendar_group.update(with_subgroups: false) }

          it "includes only layer_course" do
            expect_events(
              included: %i[layer_course],
              excluded: %i[layer_event subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
            )
          end

          context "with excluded calendar group" do
            let(:excluded_calendar_group) { Fabricate(:calendar_group, excluded: true, calendar: calendar) }

            context "layer" do
              before { excluded_calendar_group.update(group: layer) }

              context "excluding all event types" do
                before { excluded_calendar_group.update(event_type: nil) }

                context "excluding also subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end
              end

              context "excluding only plain events makes no difference" do
                before { excluded_calendar_group.update(event_type: Event.name, with_subgroups: true) }

                it "includes only layer_course" do
                  expect_events(
                    included: %i[layer_course],
                    excluded: %i[layer_event subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                  )
                end
              end

              context "excluding only courses" do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                context "excluding also subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end
              end
            end

            context "subgroup makes no difference" do
              before { excluded_calendar_group.update(group: subgroup, event_type: nil, with_subgroups: true) }

              it "includes only layer_course" do
                expect_events(
                  included: %i[layer_course],
                  excluded: %i[layer_event subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                )
              end
            end
          end
        end

        context "with subgroups" do
          before { calendar_group.update(with_subgroups: true) }

          it "includes only layer_course, subgroup_course, subsubgroup_course" do
            expect_events(
              included: %i[layer_course subgroup_course subsubgroup_course],
              excluded: %i[layer_event subgroup_event subsubgroup_event]
            )
          end

          context "with excluded calendar group" do
            let(:excluded_calendar_group) { Fabricate(:calendar_group, excluded: true, calendar: calendar) }

            context "layer" do
              before { excluded_calendar_group.update(group: layer) }

              context "excluding all event types" do
                before { excluded_calendar_group.update(event_type: nil) }

                context "excluding also subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only subgroup_course, subsubgroup_course" do
                    expect_events(
                      included: %i[subgroup_course subsubgroup_course],
                      excluded: %i[layer_event layer_course subgroup_event subsubgroup_event]
                    )
                  end
                end
              end

              context "excluding only plain events" do
                before { excluded_calendar_group.update(event_type: Event.name) }

                context "excluding also subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes only layer_course, subgroup_course, subsubgroup_course" do
                    expect_events(
                      included: %i[layer_course subgroup_course subsubgroup_course],
                      excluded: %i[layer_event subgroup_event subsubgroup_event]
                    )
                  end
                end

                context "not excluding subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only layer_course, subgroup_course, subsubgroup_course" do
                    expect_events(
                      included: %i[layer_course subgroup_course subsubgroup_course],
                      excluded: %i[layer_event subgroup_event subsubgroup_event]
                    )
                  end
                end
              end

              context "excluding only courses" do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                context "excluding also subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only subgroup_course, subsubgroup_course" do
                    expect_events(
                      included: %i[subgroup_course subsubgroup_course],
                      excluded: %i[layer_event layer_course subgroup_event subsubgroup_event]
                    )
                  end
                end
              end
            end

            context "subgroup" do
              before { excluded_calendar_group.update(group: subgroup) }

              context "excluding all event types" do
                before { excluded_calendar_group.update(event_type: nil) }

                context "excluding also subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes only layer_course" do
                    expect_events(
                      included: %i[layer_course],
                      excluded: %i[layer_event subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only layer_course, subsubgroup_course" do
                    expect_events(
                      included: %i[layer_course subsubgroup_course],
                      excluded: %i[layer_event subgroup_event subgroup_course subsubgroup_event]
                    )
                  end
                end
              end

              context "excluding only plain events makes no difference" do
                before { excluded_calendar_group.update(event_type: Event.name, with_subgroups: true) }

                it "includes only layer_course, subgroup_course, subsubgroup_course" do
                  expect_events(
                    included: %i[layer_course subgroup_course subsubgroup_course],
                    excluded: %i[layer_event subgroup_event subsubgroup_event]
                  )
                end
              end

              context "excluding only courses" do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                context "excluding also subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes only layer_course" do
                    expect_events(
                      included: %i[layer_course],
                      excluded: %i[layer_event subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only layer_course, subsubgroup_course" do
                    expect_events(
                      included: %i[layer_course subsubgroup_course],
                      excluded: %i[layer_event subgroup_event subgroup_course subsubgroup_event]
                    )
                  end
                end
              end
            end
          end
        end
      end
    end

    context "subgroup" do
      let!(:calendar_group) { calendar.included_calendar_groups.first.tap { |g| g.update(group: subgroup) } }

      context "including all event types" do
        before { calendar_group.update(event_type: nil) }

        context "without subsubgroups" do
          before { calendar_group.update(with_subgroups: false) }

          it "includes only subgroup_event, subgroup_course" do
            expect_events(
              included: %i[subgroup_event subgroup_course],
              excluded: %i[layer_event layer_course subsubgroup_event subsubgroup_course]
            )
          end

          context "with excluded calendar group" do
            let(:excluded_calendar_group) { Fabricate(:calendar_group, excluded: true, calendar: calendar) }

            context "layer" do
              before { excluded_calendar_group.update(group: layer) }

              context "excluding all event types" do
                before { excluded_calendar_group.update(event_type: nil) }

                context "excluding also subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only subgroup_event, subgroup_course" do
                    expect_events(
                      included: %i[subgroup_event subgroup_course],
                      excluded: %i[layer_event layer_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end
              end

              context "excluding only plain events" do
                before { excluded_calendar_group.update(event_type: Event.name) }

                context "excluding also subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes only subgroup_course" do
                    expect_events(
                      included: %i[subgroup_course],
                      excluded: %i[layer_event layer_course subgroup_event subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only subgroup_event, subgroup_course" do
                    expect_events(
                      included: %i[subgroup_event subgroup_course],
                      excluded: %i[layer_event layer_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end
              end

              context "excluding only courses" do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                context "excluding also subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes only subgroup_event" do
                    expect_events(
                      included: %i[subgroup_event],
                      excluded: %i[layer_event layer_course subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only subgroup_event, subgroup_course" do
                    expect_events(
                      included: %i[subgroup_event subgroup_course],
                      excluded: %i[layer_event layer_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end
              end
            end

            context "subgroup" do
              before { excluded_calendar_group.update(group: subgroup) }

              context "excluding all event types" do
                before { excluded_calendar_group.update(event_type: nil) }

                context "excluding also subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end
              end

              context "excluding only plain events" do
                before { excluded_calendar_group.update(event_type: Event.name) }

                context "excluding also subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes only subgroup_course" do
                    expect_events(
                      included: %i[subgroup_course],
                      excluded: %i[layer_event layer_course subgroup_event subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only subgroup_course" do
                    expect_events(
                      included: %i[subgroup_course],
                      excluded: %i[layer_event layer_course subgroup_event subsubgroup_event subsubgroup_course]
                    )
                  end
                end
              end

              context "excluding only courses" do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                context "excluding also subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes only subgroup_event" do
                    expect_events(
                      included: %i[subgroup_event],
                      excluded: %i[layer_event layer_course subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only subgroup_event" do
                    expect_events(
                      included: %i[subgroup_event],
                      excluded: %i[layer_event layer_course subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end
              end
            end

            context "subsubgroup makes no difference" do
              before { excluded_calendar_group.update(group: subsubgroup, event_type: nil, with_subgroups: true) }

              it "includes only subgroup_event, subgroup_course" do
                expect_events(
                  included: %i[subgroup_event subgroup_course],
                  excluded: %i[layer_event layer_course subsubgroup_event subsubgroup_course]
                )
              end
            end
          end
        end

        context "with subsubgroups" do
          before { calendar_group.update(with_subgroups: true) }

          it "includes only subgroup_event, subgroup_course, subsubgroup_event, subsubgroup_course" do
            expect_events(
              included: %i[subgroup_event subgroup_course subsubgroup_event subsubgroup_course],
              excluded: %i[layer_event layer_course]
            )
          end

          context "with excluded calendar group" do
            let(:excluded_calendar_group) { Fabricate(:calendar_group, excluded: true, calendar: calendar) }

            context "layer" do
              before { excluded_calendar_group.update(group: layer) }

              context "excluding all event types" do
                before { excluded_calendar_group.update(event_type: nil) }

                context "excluding also subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only subgroup_event, subgroup_course, subsubgroup_event, subsubgroup_course" do
                    expect_events(
                      included: %i[subgroup_event subgroup_course subsubgroup_event subsubgroup_course],
                      excluded: %i[layer_event layer_course]
                    )
                  end
                end
              end

              context "excluding only plain events" do
                before { excluded_calendar_group.update(event_type: Event.name) }

                context "excluding also subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes only subgroup_course, subsubgroup_course" do
                    expect_events(
                      included: %i[subgroup_course subsubgroup_course],
                      excluded: %i[layer_event layer_course subgroup_event subsubgroup_event]
                    )
                  end
                end

                context "not excluding subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only subgroup_event, subgroup_course, subsubgroup_event, subsubgroup_course" do
                    expect_events(
                      included: %i[subgroup_event subgroup_course subsubgroup_event subsubgroup_course],
                      excluded: %i[layer_event layer_course]
                    )
                  end
                end
              end

              context "excluding only courses" do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                context "excluding also subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes only subgroup_event, subsubgroup_event" do
                    expect_events(
                      included: %i[subgroup_event subsubgroup_event],
                      excluded: %i[layer_event layer_course subgroup_course subsubgroup_course]
                    )
                  end
                end

                context "not excluding subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only subgroup_event, subgroup_course, subsubgroup_event, subsubgroup_course" do
                    expect_events(
                      included: %i[subgroup_event subgroup_course subsubgroup_event subsubgroup_course],
                      excluded: %i[layer_event layer_course]
                    )
                  end
                end
              end
            end

            context "subgroup" do
              before { excluded_calendar_group.update(group: subgroup) }

              context "excluding all event types" do
                before { excluded_calendar_group.update(event_type: nil) }

                context "excluding also subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only subsubgroup_event, subsubgroup_course" do
                    expect_events(
                      included: %i[subsubgroup_event subsubgroup_course],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course]
                    )
                  end
                end
              end

              context "excluding only plain events" do
                before { excluded_calendar_group.update(event_type: Event.name) }

                context "excluding also subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes only subgroup_course, subsubgroup_course" do
                    expect_events(
                      included: %i[subgroup_course subsubgroup_course],
                      excluded: %i[layer_event layer_course subgroup_event subsubgroup_event]
                    )
                  end
                end

                context "not excluding subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only subgroup_course, subsubgroup_event, subsubgroup_course" do
                    expect_events(
                      included: %i[subgroup_course subsubgroup_event subsubgroup_course],
                      excluded: %i[layer_event layer_course subgroup_event]
                    )
                  end
                end
              end

              context "excluding only courses" do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                context "excluding also subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes only subgroup_event, subsubgroup_event" do
                    expect_events(
                      included: %i[subgroup_event subsubgroup_event],
                      excluded: %i[layer_event layer_course subgroup_course subsubgroup_course]
                    )
                  end
                end

                context "not excluding subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only subgroup_event, subsubgroup_event, subsubgroup_course" do
                    expect_events(
                      included: %i[subgroup_event subsubgroup_event subsubgroup_course],
                      excluded: %i[layer_event layer_course subgroup_course]
                    )
                  end
                end
              end
            end

            context "subsubgroup" do
              before { excluded_calendar_group.update(group: subsubgroup) }

              context "excluding all event types" do
                before { excluded_calendar_group.update(event_type: nil) }

                it "includes only subgroup_event, subgroup_course" do
                  expect_events(
                    included: %i[subgroup_event subgroup_course],
                    excluded: %i[layer_event layer_course subsubgroup_event subsubgroup_course]
                  )
                end
              end

              context "excluding only plain events" do
                before { excluded_calendar_group.update(event_type: Event.name) }

                it "includes only subgroup_event, subgroup_course, subsubgroup_course" do
                  expect_events(
                    included: %i[subgroup_event subgroup_course subsubgroup_course],
                    excluded: %i[layer_event layer_course subsubgroup_event]
                  )
                end
              end

              context "excluding only courses" do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                it "includes only subgroup_event, subgroup_course, subsubgroup_event" do
                  expect_events(
                    included: %i[subgroup_event subgroup_course subsubgroup_event],
                    excluded: %i[layer_event layer_course subsubgroup_course]
                  )
                end
              end
            end
          end
        end
      end

      context "including only plain events" do
        before { calendar_group.update(event_type: Event.name) }

        context "without subgroups" do
          before do
            calendar_group.update(with_subgroups: false)
          end

          it "includes only subgroup_event" do
            expect_events(
              included: %i[subgroup_event],
              excluded: %i[layer_event layer_course subgroup_course subsubgroup_event subsubgroup_course]
            )
          end

          context "with excluded calendar group" do
            let(:excluded_calendar_group) { Fabricate(:calendar_group, excluded: true, calendar: calendar) }

            context "layer" do
              before { excluded_calendar_group.update(group: layer) }

              context "excluding all event types" do
                before { excluded_calendar_group.update(event_type: nil) }

                context "excluding also subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only subgroup_event" do
                    expect_events(
                      included: %i[subgroup_event],
                      excluded: %i[layer_event layer_course subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end
              end

              context "excluding only plain events" do
                before { excluded_calendar_group.update(event_type: Event.name) }

                context "excluding also subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only subgroup_event" do
                    expect_events(
                      included: %i[subgroup_event],
                      excluded: %i[layer_event layer_course subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end
              end

              context "excluding only courses makes no difference" do
                before { excluded_calendar_group.update(event_type: Event::Course.name, with_subgroups: true) }

                it "includes only subgroup_event" do
                  expect_events(
                    included: %i[subgroup_event],
                    excluded: %i[layer_event layer_course subgroup_course subsubgroup_event subsubgroup_course]
                  )
                end
              end
            end

            context "subgroup" do
              before { excluded_calendar_group.update(group: subgroup) }

              context "excluding all event types" do
                before { excluded_calendar_group.update(event_type: nil) }

                context "excluding also subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end
              end

              context "excluding only plain events" do
                before { excluded_calendar_group.update(event_type: Event.name) }

                context "excluding also subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end
              end

              context "excluding only courses makes no difference" do
                before { excluded_calendar_group.update(event_type: Event::Course.name, with_subgroups: true) }

                it "includes only subgroup_event" do
                  expect_events(
                    included: %i[subgroup_event],
                    excluded: %i[layer_event layer_course subgroup_course subsubgroup_event subsubgroup_course]
                  )
                end
              end
            end

            context "subsubgroup makes no difference" do
              before { excluded_calendar_group.update(group: subsubgroup, event_type: nil, with_subgroups: true) }

              it "includes only subgroup_event" do
                expect_events(
                  included: %i[subgroup_event],
                  excluded: %i[layer_event layer_course subgroup_course subsubgroup_event subsubgroup_course]
                )
              end
            end
          end
        end

        context "with subgroups" do
          before { calendar_group.update(with_subgroups: true) }

          it "includes only subgroup_event, subsubgroup_event" do
            expect_events(
              included: %i[subgroup_event subsubgroup_event],
              excluded: %i[layer_event layer_course subgroup_course subsubgroup_course]
            )
          end

          context "with excluded calendar group" do
            let(:excluded_calendar_group) { Fabricate(:calendar_group, excluded: true, calendar: calendar) }

            context "layer" do
              before { excluded_calendar_group.update(group: layer) }

              context "excluding all event types" do
                before { excluded_calendar_group.update(event_type: nil) }

                context "excluding also subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only subgroup_event, subsubgroup_event" do
                    expect_events(
                      included: %i[subgroup_event subsubgroup_event],
                      excluded: %i[layer_event layer_course subgroup_course subsubgroup_course]
                    )
                  end
                end
              end

              context "excluding only plain events" do
                before { excluded_calendar_group.update(event_type: Event.name) }

                context "excluding also subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only subgroup_event, subsubgroup_event" do
                    expect_events(
                      included: %i[subgroup_event subsubgroup_event],
                      excluded: %i[layer_event layer_course subgroup_course subsubgroup_course]
                    )
                  end
                end
              end

              context "excluding only courses makes no difference" do
                before { excluded_calendar_group.update(event_type: Event::Course.name, with_subgroups: true) }

                it "includes only subgroup_event, subsubgroup_event" do
                  expect_events(
                    included: %i[subgroup_event subsubgroup_event],
                    excluded: %i[layer_event layer_course subgroup_course subsubgroup_course]
                  )
                end
              end
            end

            context "subgroup" do
              before { excluded_calendar_group.update(group: subgroup) }

              context "excluding all event types" do
                before { excluded_calendar_group.update(event_type: nil) }

                context "excluding also subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only subsubgroup_event" do
                    expect_events(
                      included: %i[subsubgroup_event],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_course]
                    )
                  end
                end
              end

              context "excluding only plain events" do
                before { excluded_calendar_group.update(event_type: Event.name) }

                context "excluding also subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only subsubgroup_event" do
                    expect_events(
                      included: %i[subsubgroup_event],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_course]
                    )
                  end
                end
              end

              context "excluding only courses makes no difference" do
                before { excluded_calendar_group.update(event_type: Event::Course.name, with_subgroups: true) }

                it "includes only subgroup_event, subsubgroup_event" do
                  expect_events(
                    included: %i[subgroup_event subsubgroup_event],
                    excluded: %i[layer_event layer_course subgroup_course subsubgroup_course]
                  )
                end
              end
            end

            context "subsubgroup" do
              before { excluded_calendar_group.update(group: subsubgroup) }

              context "excluding all event types" do
                before { excluded_calendar_group.update(event_type: nil) }

                it "includes only subgroup_event" do
                  expect_events(
                    included: %i[subgroup_event],
                    excluded: %i[layer_event layer_course subgroup_course subsubgroup_event subsubgroup_course]
                  )
                end
              end

              context "excluding only plain events" do
                before { excluded_calendar_group.update(event_type: Event.name) }

                it "includes only subgroup_event" do
                  expect_events(
                    included: %i[subgroup_event],
                    excluded: %i[layer_event layer_course subgroup_course subsubgroup_event subsubgroup_course]
                  )
                end
              end

              context "excluding only courses" do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                it "includes only subgroup_event, subsubgroup_event" do
                  expect_events(
                    included: %i[subgroup_event subsubgroup_event],
                    excluded: %i[layer_event layer_course subgroup_course subsubgroup_course]
                  )
                end
              end
            end
          end
        end
      end

      context "including only courses" do
        before { calendar_group.update(event_type: Event::Course.name) }

        context "without subgroups" do
          before { calendar_group.update(with_subgroups: false) }

          it "includes only subgroup_course" do
            expect_events(
              included: %i[subgroup_course],
              excluded: %i[layer_event layer_course subgroup_event subsubgroup_event subsubgroup_course]
            )
          end

          context "with excluded calendar group" do
            let(:excluded_calendar_group) { Fabricate(:calendar_group, excluded: true, calendar: calendar) }

            context "layer" do
              before { excluded_calendar_group.update(group: layer) }

              context "excluding all event types" do
                before { excluded_calendar_group.update(event_type: nil) }

                context "excluding also subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only subgroup_course" do
                    expect_events(
                      included: %i[subgroup_course],
                      excluded: %i[layer_event layer_course subgroup_event subsubgroup_event subsubgroup_course]
                    )
                  end
                end
              end

              context "excluding only plain events makes no difference" do
                it "includes only subgroup_course" do
                  expect_events(
                    included: %i[subgroup_course],
                    excluded: %i[layer_event layer_course subgroup_event subsubgroup_event subsubgroup_course]
                  )
                end
              end

              context "excluding only courses" do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                context "excluding also subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only subgroup_course" do
                    expect_events(
                      included: %i[subgroup_course],
                      excluded: %i[layer_event layer_course subgroup_event subsubgroup_event subsubgroup_course]
                    )
                  end
                end
              end
            end

            context "subgroup" do
              before { excluded_calendar_group.update(group: subgroup) }

              context "excluding all event types" do
                before { excluded_calendar_group.update(event_type: nil) }

                context "excluding also subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end
              end

              context "excluding only plain events makes no difference" do
                before { excluded_calendar_group.update(event_type: Event.name, with_subgroups: true) }

                it "includes only subgroup_course" do
                  expect_events(
                    included: %i[subgroup_course],
                    excluded: %i[layer_event layer_course subgroup_event subsubgroup_event subsubgroup_course]
                  )
                end
              end

              context "excluding only courses" do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                context "excluding also subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end
              end
            end

            context "subsubgroup makes no difference" do
              before { excluded_calendar_group.update(group: subsubgroup, event_type: nil, with_subgroups: true) }

              it "includes only subgroup_course" do
                expect_events(
                  included: %i[subgroup_course],
                  excluded: %i[layer_event layer_course subgroup_event subsubgroup_event subsubgroup_course]
                )
              end
            end
          end
        end

        context "with subgroups" do
          before { calendar_group.update(with_subgroups: true) }

          it "includes only subgroup_course, subsubgroup_course" do
            expect_events(
              included: %i[subgroup_course subsubgroup_course],
              excluded: %i[layer_event layer_course subgroup_event subsubgroup_event]
            )
          end

          context "with excluded calendar group" do
            let(:excluded_calendar_group) { Fabricate(:calendar_group, excluded: true, calendar: calendar) }

            context "layer" do
              before { excluded_calendar_group.update(group: layer) }

              context "excluding all event types" do
                before { excluded_calendar_group.update(event_type: nil) }

                context "excluding also subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only subgroup_course, subsubgroup_course" do
                    expect_events(
                      included: %i[subgroup_course subsubgroup_course],
                      excluded: %i[layer_event layer_course subgroup_event subsubgroup_event]
                    )
                  end
                end
              end

              context "excluding only plain events makes no difference" do
                before { excluded_calendar_group.update(event_type: Event.name, with_subgroups: true) }

                it "includes only subgroup_course, subsubgroup_course" do
                  expect_events(
                    included: %i[subgroup_course subsubgroup_course],
                    excluded: %i[layer_event layer_course subgroup_event subsubgroup_event]
                  )
                end
              end

              context "excluding only courses" do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                context "excluding also subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only subgroup_course, subsubgroup_course" do
                    expect_events(
                      included: %i[subgroup_course subsubgroup_course],
                      excluded: %i[layer_event layer_course subgroup_event subsubgroup_event]
                    )
                  end
                end
              end
            end

            context "subgroup" do
              before { excluded_calendar_group.update(group: subgroup) }

              context "excluding all event types" do
                before { excluded_calendar_group.update(event_type: nil) }

                context "excluding also subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only subsubgroup_course" do
                    expect_events(
                      included: %i[subsubgroup_course],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event]
                    )
                  end
                end
              end

              context "excluding only plain events makes no difference" do
                before { excluded_calendar_group.update(event_type: Event.name, with_subgroups: true) }

                it "includes only subgroup_course, subsubgroup_course" do
                  expect_events(
                    included: %i[subgroup_course subsubgroup_course],
                    excluded: %i[layer_event layer_course subgroup_event subsubgroup_event]
                  )
                end
              end

              context "excluding only courses" do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                context "excluding also subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it "includes none of the events" do
                    expect_events(
                      included: [],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event subsubgroup_course]
                    )
                  end
                end

                context "not excluding subsubgroups" do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it "includes only subsubgroup_course" do
                    expect_events(
                      included: %i[subsubgroup_course],
                      excluded: %i[layer_event layer_course subgroup_event subgroup_course subsubgroup_event]
                    )
                  end
                end
              end
            end

            context "subsubgroup" do
              before { excluded_calendar_group.update(group: subsubgroup) }

              context "excluding all event types" do
                before { excluded_calendar_group.update(event_type: nil) }

                it "includes only subgroup_course" do
                  expect_events(
                    included: %i[subgroup_course],
                    excluded: %i[layer_event layer_course subgroup_event subsubgroup_event subsubgroup_course]
                  )
                end
              end

              context "excluding only plain events" do
                before { excluded_calendar_group.update(event_type: Event.name) }

                it "includes only subgroup_course, subsubgroup_course" do
                  expect_events(
                    included: %i[subgroup_course subsubgroup_course],
                    excluded: %i[layer_event layer_course subgroup_event subsubgroup_event]
                  )
                end
              end

              context "excluding only courses" do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                it "includes only subgroup_course" do
                  expect_events(
                    included: %i[subgroup_course],
                    excluded: %i[layer_event layer_course subgroup_event subsubgroup_event subsubgroup_course]
                  )
                end
              end
            end
          end
        end
      end
    end
  end
end
