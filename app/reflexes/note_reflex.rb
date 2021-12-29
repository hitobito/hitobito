# frozen_string_literal: true

class NoteReflex < ApplicationReflex
  delegate :current_user, to: :connection

  def create
    puts 'asdfasdfa'
  end

  def hello
    puts 'hello reflex ...'
    @text = 'Reflex text 423 ...' + SecureRandom.hex(20)
  end

end
