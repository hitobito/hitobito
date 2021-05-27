# frozen_string_literal: true

class NoteReflex < ApplicationReflex
  delegate :current_user, to: :connection

  def create
    puts 'asdfasdfa'
  end

end
