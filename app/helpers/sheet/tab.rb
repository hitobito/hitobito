module Sheet
  class Tab

    attr_reader :label_key, :path_method, :options

    def initialize(label_key, path_method, options = {})
      @label_key = label_key
      @path_method = path_method
      @options = options
    end

    def render(view, path_args, active = false)
      renderer(view, path_args, active).render
    end

    def renderer(view, path_args, active = false)
      Renderer.new(view, self, path_args, active)
    end

    def alt_paths
      if options[:no_alt]
        []
      else
        [path_method] + (options[:alt] || [])
      end
    end

    def params
      options[:params] || {}
    end

    class Renderer
      attr_reader :view, :tab, :path_args, :entry, :active

      delegate :content_tag, :link_to, to: :view

      def initialize(view, tab, path_args, active = false)
        @view = view
        @tab = tab
        @path_args = path_args
        @entry = path_args.last
        @active = active
      end

      def render
        content_tag(:li, link_to(label, path), class: css_class) if show?
      end

      def show?
        condition = tab.options[:if]
        case condition
        when nil then true
        when Symbol then view.send(:can?, condition, entry)
        else condition.call(view, *path_args)
        end
      end

      def label
        if tab.label_key.kind_of?(Symbol)
          view.send(tab.label_key, entry)
        else
          I18n.t(tab.label_key)
        end
      end

      def path
        view.send(tab.path_method, *path_args, tab.params)
      end

      def css_class
        active && 'active'
      end
    end
  end
end