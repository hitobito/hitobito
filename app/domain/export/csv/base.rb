module Export::Csv
  # The base class for all the different csv export files.
  class Base

    class_attribute :model_class, :row_class

    attr_reader :list

    def initialize(list)
      @list = list
    end

    def to_csv(generator)
      generator << labels
      rows.each do |row|
        generator << values(row)
      end
    end

    # The list of all attributes exported to the csv.
    # overridde either this or #attribute_labels
    def attributes
      attribute_labels.keys
    end

    # A hash of all attributes mapped to their labels exported to the csv.
    # overridde either this or #attributes
    def attribute_labels
      @attribute_labels ||= build_attribute_labels
    end

    # List of all lables.
    def labels
      attribute_labels.values
    end

    private

    def build_attribute_labels
      attributes.each_with_object({}) do |attr, labels|
        labels[attr] = attribute_label(attr)
      end
    end

    def attribute_label(attr)
      human_attribute(attr)
    end

    def human_attribute(attr)
      model_class.human_attribute_name(attr)
    end

    def rows
      list.collect { |e| row_class.new(e) }
    end

    def values(row)
      attributes.collect { |attr| row.fetch(attr) }
    end

    # Decorator for a row entry.
    # Attribute values may be accessed with fetch(attr).
    # If a method named #attr is defined on the decorator class, return its value.
    # Otherwise, the attr is delegated to the entry.
    class Row

      # regexp for attribute names which are handled dynamically.
      class_attribute :dynamic_attributes
      self.dynamic_attributes = {}

      attr_reader :entry

      def initialize(entry)
        @entry = entry
      end

      def fetch(attr)
        if dynamic_attribute?(attr.to_s)
          handle_dynamic_attribute(attr)
        elsif respond_to?(attr, true)
          send(attr)
        else
          entry.send(attr)
        end
      end

      private

      def dynamic_attribute?(attr)
        dynamic_attributes.any? { |regexp, _| attr =~ regexp }
      end

      def handle_dynamic_attribute(attr)
        dynamic_attributes.each do |regexp, handler|
          if attr.to_s =~ regexp
            return send(handler, attr)
          end
        end
      end

    end

    self.row_class = Row
  end

end