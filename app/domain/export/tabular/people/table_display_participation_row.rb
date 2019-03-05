module Export::Tabular::People
  class TableDisplayParticipationRow < ParticipationRow
    attr_reader :table_display

    def initialize(entry, table_display, format = nil)
      @table_display = table_display
      super(entry, format)
    end

    private

    def value_for(attr)
      table_display.with_permission_check(attr, participation) do
        super(translate(attr))
      end
    end

    def translate(attr)
      attr.to_s.gsub('person.', '').gsub('event_question_', 'question_')
    end

  end

end
