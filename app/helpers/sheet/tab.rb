# encoding: utf-8

#  Copyright (c) 2014 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet

  # Contains the information for a tab in a specific sheet.
  # This includes:
  #  * label_key: The I18n String key to use for the label. If this value is a symbol,
  #               the helper method with this name will be called, getting the sheet
  #               entry as only argument.
  #  * path_method: A symbol for the method returning the url of the tab. The method gets
  #                 the path_args (entries of the entire sheet stack) as arguments.
  #  * options: Possible options are
  #              * :if - A symbol that corresponds to a CanCan action for the sheet entry
  #                      that must be permitted or a lambda returning true or false.
  #              * :alt - An array of symbols corresponding to path methods that contain
  #                       the beginning of path names for which the tab entry is considered active.
  #              * :no_alt - true if the main path_method argument should only be used as exact
  #                          path match but not as the beginning of the current path to consider
  #                          the tab as active. Set this for example if one tab is a main path
  #                          and other tabs are sub paths.
  #              * :params - A hash of additional params that will be passed to the path_method.
  class Tab

    attr_reader :label_key, :path_method, :options

    def initialize(label_key, path_method, options = {})
      @label_key = label_key
      @path_method = path_method
      @options = options
    end

    def renderer(view, path_args)
      Renderer.new(view, self, path_args)
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

    class Renderer < SimpleDelegator
      attr_reader :view, :tab, :path_args, :entry, :active

      delegate :content_tag, :link_to, to: :view

      def initialize(view, tab, path_args)
        super(tab)
        @view = view
        @tab = tab
        @path_args = path_args
        @entry = path_args.last
      end

      def render(active = false)
        content_tag(:li,
                    link_to(label, path),
                    class: active ? 'active' : nil)
      end

      def show?
        condition = options[:if]
        case condition
        when nil then true
        when Symbol then view.send(:can?, condition, entry)
        else condition.call(view, *path_args)
        end
      end

      def label
        if label_key.kind_of?(Symbol)
          view.send(label_key, entry)
        else
          I18n.t(label_key, default: label_key)
        end
      end

      def path
        path_for(path_method, params)
      end

      def current_page?
        view.current_page?(path_for(path_method))
      end

      def alt_path_of?(current_path)
        alt_paths.any? { |p| current_path =~ %r{/?#{path_for(p)}/?} }
      end

      private

      def path_for(method, params = {})
        view.send(method, *path_args, params)
      end

    end
  end
end
