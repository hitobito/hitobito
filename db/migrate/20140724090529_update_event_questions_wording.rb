class UpdateEventQuestionsWording < ActiveRecord::Migration
  def change
    Event::Question.find_by(event_id: nil,
                            question: 'Ich habe folgendes ÖV Abo').
                            update_attribute(:question, 'Ich habe während dem Kurs folgendes ÖV Abo')
  end
end
