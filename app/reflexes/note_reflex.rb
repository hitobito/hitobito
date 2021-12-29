# frozen_string_literal: true

class NoteReflex < ApplicationReflex
  delegate :current_user, to: :connection

  def create
    puts 'asdfasdfa'
  end

  def hello
    puts 'asdfasdf 42 42 42'
  end

end
