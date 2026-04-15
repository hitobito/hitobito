#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito_jubla and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

def available_locales(attrs)
  attrs.select do
    Settings.application.languages.keys.map(&:to_s).include?(_1.to_s.split("_").last)
  end
end

Event::QuestionTemplate.seed_once(group_id: 1,
                                  event_type: nil,
                                  default: true,
                                  inherit: true,
                                  question: Event::Question.seed_once(
                                    available_locales({
                                      question_de: "Hast du ein GA?",
                                      question_fr: "Tu as un GA?",
                                      question_it: "Hai un GA?"
                                    })
                                  ).first)

Event::QuestionTemplate.seed_once(group_id: 1,
                                  event_type: nil,
                                  default: true,
                                  inherit: true,
                                  question: Event::Question.seed_once(
                                    available_locales({
                                      question_de: "Sind Kürse besser als Anlässe?",
                                      question_fr: "Le freestyle est-il meilleur que les événements?",
                                      question_it: "Il freestyle è meglio degli event?"
                                    })
                                  ).first)
