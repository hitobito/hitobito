# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::QuestionTemplate do
  let(:template) { event_question_templates(:ga_template) }

  describe "#applicable_to" do
    it "returns applicable templates" do
      expect(Event::QuestionTemplate.applicable_to([groups(:top_layer)])).to include(template)
    end

    it "returns templates for lower layer group if inherit true" do
      template.update!(inherit: true)

      expect(Event::QuestionTemplate.applicable_to([groups(:bottom_group_one_one)])).to include(template)
    end

    it "does not return template for lower layer group if inherit false" do
      template.update!(inherit: false)

      expect(Event::QuestionTemplate.applicable_to([groups(:bottom_group_one_one)])).not_to include(template)
    end

    it "does not return template of another layer hierarchy" do
      template.update!(group: groups(:bottom_layer_one), inherit: true)

      expect(Event::QuestionTemplate.applicable_to([groups(:bottom_layer_two)])).not_to include(template)
    end

    it "does not return template for different event type" do
      template.update!(event_type: "Event::Course")

      expect(Event::QuestionTemplate.applicable_to([groups(:top_layer)])).not_to include(template)
    end

    it "does not return template if template is default false" do
      template.update!(default: false)

      expect(Event::QuestionTemplate.applicable_to([groups(:top_layer)])).not_to include(template)
    end

    it "returns no template when no groups are passed" do
      expect(Event::QuestionTemplate.applicable_to([])).to be_blank
    end
  end

  describe "#derived_questions" do
    it "nullifies template_id of derived questions when template is destroyed" do
      derived_question = template.derive_question
      derived_question.save!

      expect { template.destroy }
        .to change { derived_question.reload.template_id }.to(nil)
    end
  end

  describe "#derive_question" do
    it "creates a new question instance with new translation instances" do
      derived_question = template.derive_question

      expect(derived_question.new_record?).to be_truthy
      expect(derived_question.id).to be_nil
      expect(derived_question.created_at).to be_nil
      expect(derived_question.updated_at).to be_nil
      expect(derived_question.derived?).to be_truthy

      expect(derived_question.question_de).to eq "Ich habe folgendes ÖV Abo"
      expect(derived_question.question_fr).to eq "J'ai l'abonnement de transports publics suivant"
      expect(derived_question.choices_de).to eq "GA, Halbtax / unter 16, keine Vergünstigung"
      expect(derived_question.choices_fr).to eq "AG, demi-tarif / moins de 16 ans, pas de réduction"

      travel_to Time.zone.now do
        derived_question.save!

        expect(derived_question.created_at).to eq Time.zone.now
        expect(derived_question.updated_at).to eq Time.zone.now
      end
    end
  end
end
