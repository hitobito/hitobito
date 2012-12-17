module Sheet
  class Admin < Base
    def render_main_tabs
      view.tab_bar do |bar|
        view.render("shared/admin_tabs", bar: bar)
      end
    end
  end
end