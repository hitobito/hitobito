class GroupListDecorator 
  attr_reader :layer, :sub

  def initialize(model)
    @layer = []
    @sub = []
    model.children.order_by_type(model).each do |group|
      send(group.layer ? :layer : :sub) << group
    end
    @layer = @layer.group_by { |group| group.class.model_name.human(count: 2) } 
  end


  def label_sub
    'Untergruppen'
  end
end
