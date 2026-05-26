# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::QuestionTemplateDecorator, :draper_with_helpers do
  let(:template) { event_question_templates(:ga_template) }

  subject { template.decorate }

  describe "#event_type_label" do
    it "returns human event type name" do
      template.event_type = "Event::Course"
      expect(subject.event_type_label).to eq Event::Course.model_name.human
    end

    it "returns all when no event_type is set" do
      expect(subject.event_type_label).to eq I18n.t("global.all")
    end
  end
end
