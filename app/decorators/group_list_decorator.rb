class GroupListDecorator 
  attr_reader :layer, :sub

  def initialize(model)
    @layer = []
    @sub = []
    model.children.order_by_type(model).each do |group|
      send(group.layer ? :layer : :sub) << group
    end
  end

  def label_layer
    @layer.first.class.model_name.human(count: 2)
  end

  def label_sub
    'Untergruppen'
  end
end
