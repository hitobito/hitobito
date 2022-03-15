# frozen_string_literal: true

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Calendars::Events do

  around(:each) do |example|
    layer_previous, layer.class.event_types = layer.class.event_types, [Event, Event::Course]
    subgroup_previous, subgroup.class.event_types = subgroup.class.event_types, [Event, Event::Course]
    subsubgroup_previous, subsubgroup.class.event_types = subsubgroup.class.event_types, [Event, Event::Course]
    example.run
    layer.class.event_types = layer_previous
    subgroup.class.event_types = subgroup_previous
    subsubgroup.class.event_types = subsubgroup_previous
  end

  let(:layer) { groups(:bottom_layer_one) }
  let(:subgroup) { groups(:bottom_group_one_one) }
  let(:subsubgroup) { groups(:bottom_group_one_one_one) }

  let(:layer_event) { Fabricate(:event, groups: [layer]) }
  let(:layer_course) { Fabricate(:course, groups: [layer]) }
  let(:subgroup_event) { Fabricate(:event, groups: [subgroup]) }
  let(:subgroup_course) { Fabricate(:course, groups: [subgroup]) }
  let(:subsubgroup_event) { Fabricate(:event, groups: [subsubgroup]) }
  let(:subsubgroup_course) { Fabricate(:course, groups: [subsubgroup]) }

  let(:calendar) { Fabricate(:calendar, group: layer) }

  subject { Calendars::Events.new(calendar).events }

  context 'with included calendar group' do
    context 'layer' do
      let!(:calendar_group) { calendar.included_calendar_groups.first.tap { |g| g.update(group: layer) } }

      context 'including all event types' do
        before { calendar_group.update(event_type: nil) }

        context 'without subgroups' do
          before { calendar_group.update(with_subgroups: false) }

          it { is_expected.to include(layer_event) }
          it { is_expected.to include(layer_course) }
          it { is_expected.not_to include(subgroup_event) }
          it { is_expected.not_to include(subgroup_course) }
          it { is_expected.not_to include(subsubgroup_event) }
          it { is_expected.not_to include(subsubgroup_course) }

          context 'with excluded calendar group' do
            let(:excluded_calendar_group) { Fabricate(:calendar_group, excluded: true, calendar: calendar) }
            context 'layer' do
              before { excluded_calendar_group.update(group: layer) }

              context 'excluding all event types' do
                before { excluded_calendar_group.update(event_type: nil) }

                context 'excluding also subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end
              end

              context 'excluding only plain events' do
                before { excluded_calendar_group.update(event_type: Event.name) }

                context 'excluding also subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end
              end

              context 'excluding only courses' do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                context 'excluding also subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end
              end
            end

            context 'subgroup makes no difference' do
              before { excluded_calendar_group.update(group: subgroup, event_type: nil, with_subgroups: true) }

              it { is_expected.to include(layer_event) }
              it { is_expected.to include(layer_course) }
              it { is_expected.not_to include(subgroup_event) }
              it { is_expected.not_to include(subgroup_course) }
              it { is_expected.not_to include(subsubgroup_event) }
              it { is_expected.not_to include(subsubgroup_course) }
            end
          end
        end

        context 'with subgroups' do
          before { calendar_group.update(with_subgroups: true) }

          it { is_expected.to include(layer_event) }
          it { is_expected.to include(layer_course) }
          it { is_expected.to include(subgroup_event) }
          it { is_expected.to include(subgroup_course) }
          it { is_expected.to include(subsubgroup_event) }
          it { is_expected.to include(subsubgroup_course) }

          context 'with excluded calendar group' do
            let(:excluded_calendar_group) { Fabricate(:calendar_group, excluded: true, calendar: calendar) }
            context 'layer' do
              before { excluded_calendar_group.update(group: layer) }

              context 'excluding all event types' do
                before { excluded_calendar_group.update(event_type: nil) }

                context 'excluding also subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.to include(subgroup_event) }
                  it { is_expected.to include(subgroup_course) }
                  it { is_expected.to include(subsubgroup_event) }
                  it { is_expected.to include(subsubgroup_course) }
                end
              end

              context 'excluding only plain events' do
                before { excluded_calendar_group.update(event_type: Event.name) }

                context 'excluding also subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.to include(subsubgroup_course) }
                end

                context 'not excluding subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.to include(layer_course) }
                  it { is_expected.to include(subgroup_event) }
                  it { is_expected.to include(subgroup_course) }
                  it { is_expected.to include(subsubgroup_event) }
                  it { is_expected.to include(subsubgroup_course) }
                end
              end

              context 'excluding only courses' do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                context 'excluding also subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.to include(subgroup_event) }
                  it { is_expected.to include(subgroup_course) }
                  it { is_expected.to include(subsubgroup_event) }
                  it { is_expected.to include(subsubgroup_course) }
                end
              end
            end

            context 'subgroup' do
              before { excluded_calendar_group.update(group: subgroup) }

              context 'excluding all event types' do
                before { excluded_calendar_group.update(event_type: nil) }

                context 'excluding also subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.to include(layer_event) }
                  it { is_expected.to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.to include(layer_event) }
                  it { is_expected.to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.to include(subsubgroup_event) }
                  it { is_expected.to include(subsubgroup_course) }
                end
              end

              context 'excluding only plain events' do
                before { excluded_calendar_group.update(event_type: Event.name) }

                context 'excluding also subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.to include(layer_event) }
                  it { is_expected.to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.to include(subsubgroup_course) }
                end

                context 'not excluding subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.to include(layer_event) }
                  it { is_expected.to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.to include(subgroup_course) }
                  it { is_expected.to include(subsubgroup_event) }
                  it { is_expected.to include(subsubgroup_course) }
                end
              end

              context 'excluding only courses' do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                context 'excluding also subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.to include(layer_event) }
                  it { is_expected.to include(layer_course) }
                  it { is_expected.to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.to include(layer_event) }
                  it { is_expected.to include(layer_course) }
                  it { is_expected.to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.to include(subsubgroup_event) }
                  it { is_expected.to include(subsubgroup_course) }
                end
              end
            end
          end

          context '' do
            let(:tag_hello) { ActsAsTaggableOn::Tag.find_by(name: 'hello') }
            let(:tag_world) { ActsAsTaggableOn::Tag.find_by(name: 'world') }

            before do
              layer_event.update!(tag_list: 'hello, world')
              layer_course.update!(tag_list: 'foo')
              subgroup_event.update!(tag_list: 'world, foo')
              subgroup_course.update!(tag_list: 'hello, foo')
              subsubgroup_event.update!(tag_list: '')
              subsubgroup_course.update!(tag_list: 'hello')
            end

            context 'filtering by a single tag' do
              let!(:included_tag_hello) { Fabricate(:calendar_tag, excluded: false, calendar: calendar, tag: tag_hello) }

              it { is_expected.to include(layer_event) }
              it { is_expected.not_to include(layer_course) }
              it { is_expected.not_to include(subgroup_event) }
              it { is_expected.to include(subgroup_course) }
              it { is_expected.not_to include(subsubgroup_event) }
              it { is_expected.to include(subsubgroup_course) }
            end

            context 'filtering by multiple tags includes all events containing any of the tags' do
              let!(:included_tag_hello) { Fabricate(:calendar_tag, excluded: false, calendar: calendar, tag: tag_hello) }
              let!(:included_tag_world) { Fabricate(:calendar_tag, excluded: false, calendar: calendar, tag: tag_world) }

              it { is_expected.to include(layer_event) }
              it { is_expected.not_to include(layer_course) }
              it { is_expected.to include(subgroup_event) }
              it { is_expected.to include(subgroup_course) }
              it { is_expected.not_to include(subsubgroup_event) }
              it { is_expected.to include(subsubgroup_course) }
            end

            context 'excluding a single tag' do
              let!(:excluded_tag_hello) { Fabricate(:calendar_tag, excluded: true, calendar: calendar, tag: tag_hello) }

              it { is_expected.not_to include(layer_event) }
              it { is_expected.to include(layer_course) }
              it { is_expected.to include(subgroup_event) }
              it { is_expected.not_to include(subgroup_course) }
              it { is_expected.to include(subsubgroup_event) }
              it { is_expected.not_to include(subsubgroup_course) }
            end

            context 'excluding multiple tags leaves only events containing none of the tags' do
              let!(:excluded_tag_hello) { Fabricate(:calendar_tag, excluded: true, calendar: calendar, tag: tag_hello) }
              let!(:excluded_tag_world) { Fabricate(:calendar_tag, excluded: true, calendar: calendar, tag: tag_world) }

              it { is_expected.not_to include(layer_event) }
              it { is_expected.to include(layer_course) }
              it { is_expected.not_to include(subgroup_event) }
              it { is_expected.not_to include(subgroup_course) }
              it { is_expected.to include(subsubgroup_event) }
              it { is_expected.not_to include(subsubgroup_course) }
            end

            context 'including and excluding some tags, excluding takes precedence' do
              let!(:included_tag_hello) { Fabricate(:calendar_tag, excluded: false, calendar: calendar, tag: tag_hello) }
              let!(:excluded_tag_world) { Fabricate(:calendar_tag, excluded: true, calendar: calendar, tag: tag_world) }

              it { is_expected.not_to include(layer_event) }
              it { is_expected.not_to include(layer_course) }
              it { is_expected.not_to include(subgroup_event) }
              it { is_expected.to include(subgroup_course) }
              it { is_expected.not_to include(subsubgroup_event) }
              it { is_expected.to include(subsubgroup_course) }
            end
          end
        end
      end

      context 'including only plain events' do
        before { calendar_group.update(event_type: Event.name) }

        context 'without subgroups' do
          before do
            calendar_group.update(with_subgroups: false)
          end

          it { is_expected.to include(layer_event) }
          it { is_expected.not_to include(layer_course) }
          it { is_expected.not_to include(subgroup_event) }
          it { is_expected.not_to include(subgroup_course) }
          it { is_expected.not_to include(subsubgroup_event) }
          it { is_expected.not_to include(subsubgroup_course) }

          context 'with excluded calendar group' do
            let(:excluded_calendar_group) { Fabricate(:calendar_group, excluded: true, calendar: calendar) }
            context 'layer' do
              before { excluded_calendar_group.update(group: layer) }

              context 'excluding all event types' do
                before { excluded_calendar_group.update(event_type: nil) }

                context 'excluding also subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end
              end

              context 'excluding only plain events' do
                before { excluded_calendar_group.update(event_type: Event.name) }

                context 'excluding also subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end
              end

              context 'excluding only courses makes no difference' do
                before { excluded_calendar_group.update(event_type: Event::Course.name, with_subgroups: true) }

                it { is_expected.to include(layer_event) }
                it { is_expected.not_to include(layer_course) }
                it { is_expected.not_to include(subgroup_event) }
                it { is_expected.not_to include(subgroup_course) }
                it { is_expected.not_to include(subsubgroup_event) }
                it { is_expected.not_to include(subsubgroup_course) }
              end
            end

            context 'subgroup makes no difference' do
              before { excluded_calendar_group.update(group: subgroup, event_type: nil, with_subgroups: true) }

              it { is_expected.to include(layer_event) }
              it { is_expected.not_to include(layer_course) }
              it { is_expected.not_to include(subgroup_event) }
              it { is_expected.not_to include(subgroup_course) }
              it { is_expected.not_to include(subsubgroup_event) }
              it { is_expected.not_to include(subsubgroup_course) }
            end
          end
        end

        context 'with subgroups' do
          before { calendar_group.update(with_subgroups: true) }

          it { is_expected.to include(layer_event) }
          it { is_expected.not_to include(layer_course) }
          it { is_expected.to include(subgroup_event) }
          it { is_expected.not_to include(subgroup_course) }
          it { is_expected.to include(subsubgroup_event) }
          it { is_expected.not_to include(subsubgroup_course) }

          context 'with excluded calendar group' do
            let(:excluded_calendar_group) { Fabricate(:calendar_group, excluded: true, calendar: calendar) }
            context 'layer' do
              before { excluded_calendar_group.update(group: layer) }

              context 'excluding all event types' do
                before { excluded_calendar_group.update(event_type: nil) }

                context 'excluding also subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end
              end

              context 'excluding only plain events' do
                before { excluded_calendar_group.update(event_type: Event.name) }

                context 'excluding also subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end
              end

              context 'excluding only courses' do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                context 'excluding also subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end
              end
            end

            context 'subgroup' do
              before { excluded_calendar_group.update(group: subgroup) }

              context 'excluding all event types' do
                before { excluded_calendar_group.update(event_type: nil) }

                context 'excluding also subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end
              end

              context 'excluding only plain events' do
                before { excluded_calendar_group.update(event_type: Event.name) }

                context 'excluding also subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end
              end

              context 'excluding only courses makes no difference' do
                before { excluded_calendar_group.update(event_type: Event::Course.name, with_subgroups: true) }

                it { is_expected.to include(layer_event) }
                it { is_expected.not_to include(layer_course) }
                it { is_expected.to include(subgroup_event) }
                it { is_expected.not_to include(subgroup_course) }
                it { is_expected.to include(subsubgroup_event) }
                it { is_expected.not_to include(subsubgroup_course) }
              end
            end
          end
        end
      end

      context 'including only courses' do
        before { calendar_group.update(event_type: Event::Course.name) }

        context 'without subgroups' do
          before { calendar_group.update(with_subgroups: false) }

          it { is_expected.not_to include(layer_event) }
          it { is_expected.to include(layer_course) }
          it { is_expected.not_to include(subgroup_event) }
          it { is_expected.not_to include(subgroup_course) }
          it { is_expected.not_to include(subsubgroup_event) }
          it { is_expected.not_to include(subsubgroup_course) }

          context 'with excluded calendar group' do
            let(:excluded_calendar_group) { Fabricate(:calendar_group, excluded: true, calendar: calendar) }
            context 'layer' do
              before { excluded_calendar_group.update(group: layer) }

              context 'excluding all event types' do
                before { excluded_calendar_group.update(event_type: nil) }

                context 'excluding also subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end
              end

              context 'excluding only plain events makes no difference' do
                before { excluded_calendar_group.update(event_type: Event.name, with_subgroups: true) }

                it { is_expected.not_to include(layer_event) }
                it { is_expected.to include(layer_course) }
                it { is_expected.not_to include(subgroup_event) }
                it { is_expected.not_to include(subgroup_course) }
                it { is_expected.not_to include(subsubgroup_event) }
                it { is_expected.not_to include(subsubgroup_course) }
              end

              context 'excluding only courses' do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                context 'excluding also subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end
              end
            end

            context 'subgroup makes no difference' do
              before { excluded_calendar_group.update(group: subgroup, event_type: nil, with_subgroups: true) }

              it { is_expected.not_to include(layer_event) }
              it { is_expected.to include(layer_course) }
              it { is_expected.not_to include(subgroup_event) }
              it { is_expected.not_to include(subgroup_course) }
              it { is_expected.not_to include(subsubgroup_event) }
              it { is_expected.not_to include(subsubgroup_course) }
            end
          end
        end

        context 'with subgroups' do
          before { calendar_group.update(with_subgroups: true) }

          it { is_expected.not_to include(layer_event) }
          it { is_expected.to include(layer_course) }
          it { is_expected.not_to include(subgroup_event) }
          it { is_expected.to include(subgroup_course) }
          it { is_expected.not_to include(subsubgroup_event) }
          it { is_expected.to include(subsubgroup_course) }

          context 'with excluded calendar group' do
            let(:excluded_calendar_group) { Fabricate(:calendar_group, excluded: true, calendar: calendar) }
            context 'layer' do
              before { excluded_calendar_group.update(group: layer) }

              context 'excluding all event types' do
                before { excluded_calendar_group.update(event_type: nil) }

                context 'excluding also subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.to include(subsubgroup_course) }
                end
              end

              context 'excluding only plain events' do
                before { excluded_calendar_group.update(event_type: Event.name) }

                context 'excluding also subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.to include(subsubgroup_course) }
                end

                context 'not excluding subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.to include(subsubgroup_course) }
                end
              end

              context 'excluding only courses' do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                context 'excluding also subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.to include(subsubgroup_course) }
                end
              end
            end

            context 'subgroup' do
              before { excluded_calendar_group.update(group: subgroup) }

              context 'excluding all event types' do
                before { excluded_calendar_group.update(event_type: nil) }

                context 'excluding also subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.to include(subsubgroup_course) }
                end
              end

              context 'excluding only plain events makes no difference' do
                before { excluded_calendar_group.update(event_type: Event.name, with_subgroups: true) }

                it { is_expected.not_to include(layer_event) }
                it { is_expected.to include(layer_course) }
                it { is_expected.not_to include(subgroup_event) }
                it { is_expected.to include(subgroup_course) }
                it { is_expected.not_to include(subsubgroup_event) }
                it { is_expected.to include(subsubgroup_course) }
              end

              context 'excluding only courses' do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                context 'excluding also subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.to include(subsubgroup_course) }
                end
              end
            end
          end
        end
      end
    end

    context 'subgroup' do
      let!(:calendar_group) { calendar.included_calendar_groups.first.tap { |g| g.update(group: subgroup) } }

      context 'including all event types' do
        before { calendar_group.update(event_type: nil) }

        context 'without subsubgroups' do
          before { calendar_group.update(with_subgroups: false) }

          it { is_expected.not_to include(layer_event) }
          it { is_expected.not_to include(layer_course) }
          it { is_expected.to include(subgroup_event) }
          it { is_expected.to include(subgroup_course) }
          it { is_expected.not_to include(subsubgroup_event) }
          it { is_expected.not_to include(subsubgroup_course) }

          context 'with excluded calendar group' do
            let(:excluded_calendar_group) { Fabricate(:calendar_group, excluded: true, calendar: calendar) }
            context 'layer' do
              before { excluded_calendar_group.update(group: layer) }

              context 'excluding all event types' do
                before { excluded_calendar_group.update(event_type: nil) }

                context 'excluding also subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.to include(subgroup_event) }
                  it { is_expected.to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end
              end

              context 'excluding only plain events' do
                before { excluded_calendar_group.update(event_type: Event.name) }

                context 'excluding also subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.to include(subgroup_event) }
                  it { is_expected.to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end
              end

              context 'excluding only courses' do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                context 'excluding also subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.to include(subgroup_event) }
                  it { is_expected.to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end
              end
            end

            context 'subgroup' do
              before { excluded_calendar_group.update(group: subgroup) }

              context 'excluding all event types' do
                before { excluded_calendar_group.update(event_type: nil) }

                context 'excluding also subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end
              end

              context 'excluding only plain events' do
                before { excluded_calendar_group.update(event_type: Event.name) }

                context 'excluding also subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end
              end

              context 'excluding only courses' do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                context 'excluding also subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end
              end
            end

            context 'subsubgroup makes no difference' do
              before { excluded_calendar_group.update(group: subsubgroup, event_type: nil, with_subgroups: true) }

              it { is_expected.not_to include(layer_event) }
              it { is_expected.not_to include(layer_course) }
              it { is_expected.to include(subgroup_event) }
              it { is_expected.to include(subgroup_course) }
              it { is_expected.not_to include(subsubgroup_event) }
              it { is_expected.not_to include(subsubgroup_course) }
            end
          end
        end

        context 'with subsubgroups' do
          before { calendar_group.update(with_subgroups: true) }

          it { is_expected.not_to include(layer_event) }
          it { is_expected.not_to include(layer_course) }
          it { is_expected.to include(subgroup_event) }
          it { is_expected.to include(subgroup_course) }
          it { is_expected.to include(subsubgroup_event) }
          it { is_expected.to include(subsubgroup_course) }

          context 'with excluded calendar group' do
            let(:excluded_calendar_group) { Fabricate(:calendar_group, excluded: true, calendar: calendar) }
            context 'layer' do
              before { excluded_calendar_group.update(group: layer) }

              context 'excluding all event types' do
                before { excluded_calendar_group.update(event_type: nil) }

                context 'excluding also subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.to include(subgroup_event) }
                  it { is_expected.to include(subgroup_course) }
                  it { is_expected.to include(subsubgroup_event) }
                  it { is_expected.to include(subsubgroup_course) }
                end
              end

              context 'excluding only plain events' do
                before { excluded_calendar_group.update(event_type: Event.name) }

                context 'excluding also subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.to include(subsubgroup_course) }
                end

                context 'not excluding subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.to include(subgroup_event) }
                  it { is_expected.to include(subgroup_course) }
                  it { is_expected.to include(subsubgroup_event) }
                  it { is_expected.to include(subsubgroup_course) }
                end
              end

              context 'excluding only courses' do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                context 'excluding also subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.to include(subgroup_event) }
                  it { is_expected.to include(subgroup_course) }
                  it { is_expected.to include(subsubgroup_event) }
                  it { is_expected.to include(subsubgroup_course) }
                end
              end
            end

            context 'subgroup' do
              before { excluded_calendar_group.update(group: subgroup) }

              context 'excluding all event types' do
                before { excluded_calendar_group.update(event_type: nil) }

                context 'excluding also subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.to include(subsubgroup_event) }
                  it { is_expected.to include(subsubgroup_course) }
                end
              end

              context 'excluding only plain events' do
                before { excluded_calendar_group.update(event_type: Event.name) }

                context 'excluding also subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.to include(subsubgroup_course) }
                end

                context 'not excluding subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.to include(subgroup_course) }
                  it { is_expected.to include(subsubgroup_event) }
                  it { is_expected.to include(subsubgroup_course) }
                end
              end

              context 'excluding only courses' do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                context 'excluding also subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.to include(subsubgroup_event) }
                  it { is_expected.to include(subsubgroup_course) }
                end
              end
            end

            context 'subsubgroup' do
              before { excluded_calendar_group.update(group: subsubgroup) }

              context 'excluding all event types' do
                before { excluded_calendar_group.update(event_type: nil) }

                it { is_expected.not_to include(layer_event) }
                it { is_expected.not_to include(layer_course) }
                it { is_expected.to include(subgroup_event) }
                it { is_expected.to include(subgroup_course) }
                it { is_expected.not_to include(subsubgroup_event) }
                it { is_expected.not_to include(subsubgroup_course) }
              end

              context 'excluding only plain events' do
                before { excluded_calendar_group.update(event_type: Event.name) }

                it { is_expected.not_to include(layer_event) }
                it { is_expected.not_to include(layer_course) }
                it { is_expected.to include(subgroup_event) }
                it { is_expected.to include(subgroup_course) }
                it { is_expected.not_to include(subsubgroup_event) }
                it { is_expected.to include(subsubgroup_course) }
              end

              context 'excluding only courses' do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                it { is_expected.not_to include(layer_event) }
                it { is_expected.not_to include(layer_course) }
                it { is_expected.to include(subgroup_event) }
                it { is_expected.to include(subgroup_course) }
                it { is_expected.to include(subsubgroup_event) }
                it { is_expected.not_to include(subsubgroup_course) }
              end
            end
          end
        end
      end

      context 'including only plain events' do
        before { calendar_group.update(event_type: Event.name) }

        context 'without subgroups' do
          before do
            calendar_group.update(with_subgroups: false)
          end

          it { is_expected.not_to include(layer_event) }
          it { is_expected.not_to include(layer_course) }
          it { is_expected.to include(subgroup_event) }
          it { is_expected.not_to include(subgroup_course) }
          it { is_expected.not_to include(subsubgroup_event) }
          it { is_expected.not_to include(subsubgroup_course) }

          context 'with excluded calendar group' do
            let(:excluded_calendar_group) { Fabricate(:calendar_group, excluded: true, calendar: calendar) }
            context 'layer' do
              before { excluded_calendar_group.update(group: layer) }

              context 'excluding all event types' do
                before { excluded_calendar_group.update(event_type: nil) }

                context 'excluding also subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end
              end

              context 'excluding only plain events' do
                before { excluded_calendar_group.update(event_type: Event.name) }

                context 'excluding also subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end
              end

              context 'excluding only courses makes no difference' do
                before { excluded_calendar_group.update(event_type: Event::Course.name, with_subgroups: true) }

                it { is_expected.not_to include(layer_event) }
                it { is_expected.not_to include(layer_course) }
                it { is_expected.to include(subgroup_event) }
                it { is_expected.not_to include(subgroup_course) }
                it { is_expected.not_to include(subsubgroup_event) }
                it { is_expected.not_to include(subsubgroup_course) }
              end
            end

            context 'subgroup' do
              before { excluded_calendar_group.update(group: subgroup) }

              context 'excluding all event types' do
                before { excluded_calendar_group.update(event_type: nil) }

                context 'excluding also subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end
              end

              context 'excluding only plain events' do
                before { excluded_calendar_group.update(event_type: Event.name) }

                context 'excluding also subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end
              end

              context 'excluding only courses makes no difference' do
                before { excluded_calendar_group.update(event_type: Event::Course.name, with_subgroups: true) }

                it { is_expected.not_to include(layer_event) }
                it { is_expected.not_to include(layer_course) }
                it { is_expected.to include(subgroup_event) }
                it { is_expected.not_to include(subgroup_course) }
                it { is_expected.not_to include(subsubgroup_event) }
                it { is_expected.not_to include(subsubgroup_course) }
              end
            end

            context 'subsubgroup makes no difference' do
              before { excluded_calendar_group.update(group: subsubgroup, event_type: nil, with_subgroups: true) }

              it { is_expected.not_to include(layer_event) }
              it { is_expected.not_to include(layer_course) }
              it { is_expected.to include(subgroup_event) }
              it { is_expected.not_to include(subgroup_course) }
              it { is_expected.not_to include(subsubgroup_event) }
              it { is_expected.not_to include(subsubgroup_course) }
            end
          end
        end

        context 'with subgroups' do
          before { calendar_group.update(with_subgroups: true) }

          it { is_expected.not_to include(layer_event) }
          it { is_expected.not_to include(layer_course) }
          it { is_expected.to include(subgroup_event) }
          it { is_expected.not_to include(subgroup_course) }
          it { is_expected.to include(subsubgroup_event) }
          it { is_expected.not_to include(subsubgroup_course) }

          context 'with excluded calendar group' do
            let(:excluded_calendar_group) { Fabricate(:calendar_group, excluded: true, calendar: calendar) }
            context 'layer' do
              before { excluded_calendar_group.update(group: layer) }

              context 'excluding all event types' do
                before { excluded_calendar_group.update(event_type: nil) }

                context 'excluding also subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end
              end

              context 'excluding only plain events' do
                before { excluded_calendar_group.update(event_type: Event.name) }

                context 'excluding also subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end
              end

              context 'excluding only courses makes no difference' do
                before { excluded_calendar_group.update(event_type: Event::Course.name, with_subgroups: true) }

                it { is_expected.not_to include(layer_event) }
                it { is_expected.not_to include(layer_course) }
                it { is_expected.to include(subgroup_event) }
                it { is_expected.not_to include(subgroup_course) }
                it { is_expected.to include(subsubgroup_event) }
                it { is_expected.not_to include(subsubgroup_course) }
              end
            end

            context 'subgroup' do
              before { excluded_calendar_group.update(group: subgroup) }

              context 'excluding all event types' do
                before { excluded_calendar_group.update(event_type: nil) }

                context 'excluding also subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end
              end

              context 'excluding only plain events' do
                before { excluded_calendar_group.update(event_type: Event.name) }

                context 'excluding also subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end
              end

              context 'excluding only courses makes no difference' do
                before { excluded_calendar_group.update(event_type: Event::Course.name, with_subgroups: true) }

                it { is_expected.not_to include(layer_event) }
                it { is_expected.not_to include(layer_course) }
                it { is_expected.to include(subgroup_event) }
                it { is_expected.not_to include(subgroup_course) }
                it { is_expected.to include(subsubgroup_event) }
                it { is_expected.not_to include(subsubgroup_course) }
              end
            end

            context 'subsubgroup' do
              before { excluded_calendar_group.update(group: subsubgroup) }

              context 'excluding all event types' do
                before { excluded_calendar_group.update(event_type: nil) }

                it { is_expected.not_to include(layer_event) }
                it { is_expected.not_to include(layer_course) }
                it { is_expected.to include(subgroup_event) }
                it { is_expected.not_to include(subgroup_course) }
                it { is_expected.not_to include(subsubgroup_event) }
                it { is_expected.not_to include(subsubgroup_course) }
              end

              context 'excluding only plain events' do
                before { excluded_calendar_group.update(event_type: Event.name) }

                it { is_expected.not_to include(layer_event) }
                it { is_expected.not_to include(layer_course) }
                it { is_expected.to include(subgroup_event) }
                it { is_expected.not_to include(subgroup_course) }
                it { is_expected.not_to include(subsubgroup_event) }
                it { is_expected.not_to include(subsubgroup_course) }
              end

              context 'excluding only courses' do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                it { is_expected.not_to include(layer_event) }
                it { is_expected.not_to include(layer_course) }
                it { is_expected.to include(subgroup_event) }
                it { is_expected.not_to include(subgroup_course) }
                it { is_expected.to include(subsubgroup_event) }
                it { is_expected.not_to include(subsubgroup_course) }
              end
            end
          end
        end
      end

      context 'including only courses' do
        before { calendar_group.update(event_type: Event::Course.name) }

        context 'without subgroups' do
          before { calendar_group.update(with_subgroups: false) }

          it { is_expected.not_to include(layer_event) }
          it { is_expected.not_to include(layer_course) }
          it { is_expected.not_to include(subgroup_event) }
          it { is_expected.to include(subgroup_course) }
          it { is_expected.not_to include(subsubgroup_event) }
          it { is_expected.not_to include(subsubgroup_course) }

          context 'with excluded calendar group' do
            let(:excluded_calendar_group) { Fabricate(:calendar_group, excluded: true, calendar: calendar) }
            context 'layer' do
              before { excluded_calendar_group.update(group: layer) }

              context 'excluding all event types' do
                before { excluded_calendar_group.update(event_type: nil) }

                context 'excluding also subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end
              end

              context 'excluding only plain events makes no difference' do

                it { is_expected.not_to include(layer_event) }
                it { is_expected.not_to include(layer_course) }
                it { is_expected.not_to include(subgroup_event) }
                it { is_expected.to include(subgroup_course) }
                it { is_expected.not_to include(subsubgroup_event) }
                it { is_expected.not_to include(subsubgroup_course) }
              end

              context 'excluding only courses' do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                context 'excluding also subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end
              end
            end

            context 'subgroup' do
              before { excluded_calendar_group.update(group: subgroup) }

              context 'excluding all event types' do
                before { excluded_calendar_group.update(event_type: nil) }

                context 'excluding also subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end
              end

              context 'excluding only plain events makes no difference' do
                before { excluded_calendar_group.update(event_type: Event.name, with_subgroups: true) }

                it { is_expected.not_to include(layer_event) }
                it { is_expected.not_to include(layer_course) }
                it { is_expected.not_to include(subgroup_event) }
                it { is_expected.to include(subgroup_course) }
                it { is_expected.not_to include(subsubgroup_event) }
                it { is_expected.not_to include(subsubgroup_course) }
              end

              context 'excluding only courses' do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                context 'excluding also subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end
              end
            end

            context 'subsubgroup makes no difference' do
              before { excluded_calendar_group.update(group: subsubgroup, event_type: nil, with_subgroups: true) }

              it { is_expected.not_to include(layer_event) }
              it { is_expected.not_to include(layer_course) }
              it { is_expected.not_to include(subgroup_event) }
              it { is_expected.to include(subgroup_course) }
              it { is_expected.not_to include(subsubgroup_event) }
              it { is_expected.not_to include(subsubgroup_course) }
            end
          end
        end

        context 'with subgroups' do
          before { calendar_group.update(with_subgroups: true) }

          it { is_expected.not_to include(layer_event) }
          it { is_expected.not_to include(layer_course) }
          it { is_expected.not_to include(subgroup_event) }
          it { is_expected.to include(subgroup_course) }
          it { is_expected.not_to include(subsubgroup_event) }
          it { is_expected.to include(subsubgroup_course) }

          context 'with excluded calendar group' do
            let(:excluded_calendar_group) { Fabricate(:calendar_group, excluded: true, calendar: calendar) }
            context 'layer' do
              before { excluded_calendar_group.update(group: layer) }

              context 'excluding all event types' do
                before { excluded_calendar_group.update(event_type: nil) }

                context 'excluding also subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.to include(subsubgroup_course) }
                end
              end

              context 'excluding only plain events makes no difference' do
                before { excluded_calendar_group.update(event_type: Event.name, with_subgroups: true) }

                it { is_expected.not_to include(layer_event) }
                it { is_expected.not_to include(layer_course) }
                it { is_expected.not_to include(subgroup_event) }
                it { is_expected.to include(subgroup_course) }
                it { is_expected.not_to include(subsubgroup_event) }
                it { is_expected.to include(subsubgroup_course) }
              end

              context 'excluding only courses' do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                context 'excluding also subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.to include(subsubgroup_course) }
                end
              end
            end

            context 'subgroup' do
              before { excluded_calendar_group.update(group: subgroup) }

              context 'excluding all event types' do
                before { excluded_calendar_group.update(event_type: nil) }

                context 'excluding also subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.to include(subsubgroup_course) }
                end
              end

              context 'excluding only plain events makes no difference' do
                before { excluded_calendar_group.update(event_type: Event.name, with_subgroups: true) }

                it { is_expected.not_to include(layer_event) }
                it { is_expected.not_to include(layer_course) }
                it { is_expected.not_to include(subgroup_event) }
                it { is_expected.to include(subgroup_course) }
                it { is_expected.not_to include(subsubgroup_event) }
                it { is_expected.to include(subsubgroup_course) }
              end

              context 'excluding only courses' do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                context 'excluding also subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: true) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.not_to include(subsubgroup_course) }
                end

                context 'not excluding subsubgroups' do
                  before { excluded_calendar_group.update(with_subgroups: false) }

                  it { is_expected.not_to include(layer_event) }
                  it { is_expected.not_to include(layer_course) }
                  it { is_expected.not_to include(subgroup_event) }
                  it { is_expected.not_to include(subgroup_course) }
                  it { is_expected.not_to include(subsubgroup_event) }
                  it { is_expected.to include(subsubgroup_course) }
                end
              end
            end

            context 'subsubgroup' do
              before { excluded_calendar_group.update(group: subsubgroup) }

              context 'excluding all event types' do
                before { excluded_calendar_group.update(event_type: nil) }

                it { is_expected.not_to include(layer_event) }
                it { is_expected.not_to include(layer_course) }
                it { is_expected.not_to include(subgroup_event) }
                it { is_expected.to include(subgroup_course) }
                it { is_expected.not_to include(subsubgroup_event) }
                it { is_expected.not_to include(subsubgroup_course) }
              end

              context 'excluding only plain events' do
                before { excluded_calendar_group.update(event_type: Event.name) }

                it { is_expected.not_to include(layer_event) }
                it { is_expected.not_to include(layer_course) }
                it { is_expected.not_to include(subgroup_event) }
                it { is_expected.to include(subgroup_course) }
                it { is_expected.not_to include(subsubgroup_event) }
                it { is_expected.to include(subsubgroup_course) }
              end

              context 'excluding only courses' do
                before { excluded_calendar_group.update(event_type: Event::Course.name) }

                it { is_expected.not_to include(layer_event) }
                it { is_expected.not_to include(layer_course) }
                it { is_expected.not_to include(subgroup_event) }
                it { is_expected.to include(subgroup_course) }
                it { is_expected.not_to include(subsubgroup_event) }
                it { is_expected.not_to include(subsubgroup_course) }
              end
            end
          end
        end
      end
    end
  end
end
