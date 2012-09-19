module DisplayCase
  class Exhibit
    # This method is required so that exhibits play nice with cancan
    def kind_of?(klass)
      klass >= self.class ? true : super
    end
    
  end
end