# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::QuestionTemplateAbility do
  let(:user) { role.person }
  let(:group) { role.group }
  let(:top_group) { groups(:top_group) }
  let(:bottom_layer) { groups(:bottom_layer_one) }
  let(:template) { event_question_templates(:ga_template) }

  subject { Ability.new(user.reload) }

  context :layer_and_below_full do
    let(:role) { Fabricate(Group::TopGroup::Leader.name.to_sym, group: top_group) }

    it "may create template in his layer" do
      is_expected.to be_able_to(:create, Event::QuestionTemplate.new(group: group))
    end

    %i[update show edit destroy].each do |action|
      it "may #{action} template in his layer" do
        is_expected.to be_able_to(action, template)
      end
    end

    %i[update show edit destroy].each do |action|
      it "may #{action} template in layer below" do
        template.tap { _1.update!(group: bottom_layer) }
        is_expected.to be_able_to(action, template)
      end
    end
  end

  context :layer_full do
    let(:role) { Fabricate(Group::TopGroup::LocalGuide.name.to_sym, group: top_group) }

    it "may create template in his layer" do
      is_expected.to be_able_to(:create, Event::QuestionTemplate.new(group: group))
    end

    %i[update show edit destroy].each do |action|
      it "may #{action} template in his layer" do
        is_expected.to be_able_to(action, template)
      end
    end

    %i[update show edit destroy].each do |action|
      it "may not #{action} template in layer below" do
        template.tap { _1.update!(group: bottom_layer) }
        is_expected.not_to be_able_to(action, template)
      end
    end
  end
end
