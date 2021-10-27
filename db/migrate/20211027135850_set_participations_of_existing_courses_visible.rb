class SetParticipationsOfExistingCoursesVisible < ActiveRecord::Migration[6.0]
  def up
    up_only do
      say_with_time('Make participations of courses visible to participants') do
        execute(<<~SQL.split.join(' '))
          UPDATE events
          SET participations_visible = 1
          WHERE #{connection.quote_column_name('type')} = 'Event::Course'
        SQL
      end
    end
  end
end
