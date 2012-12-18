module Sheet
  class Event
    class List < Sheet::Base
      
      def render_tabs
        view.tab_bar do |bar|
          view.render("event/lists/tabs", bar: bar)
        end
      end
    end
  end
end