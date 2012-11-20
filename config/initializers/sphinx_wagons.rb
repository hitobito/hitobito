module ActiveRecord
  class Base
    
    class_attribute :sphinx_partial_indizes
    
    class << self
      def define_partial_index(&block)
        ThinkingSphinx.context.add_indexed_model self
        self.sphinx_partial_indizes ||= []
        self.sphinx_partial_indizes << block
      end
      
      def define_partial_indizes!
        if sphinx_partial_indizes.present? && connection.adapter_name.downcase != 'sqlite'
          indizes = sphinx_partial_indizes
          #puts "defining #{indizes.size} indizes for #{name}"
          define_index do
            indizes.each {|i| self.instance_eval(&i) }
          end
        end
      end
    end
    
  end
end


