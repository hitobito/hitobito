
class PlainObjectFormBuilder < StandardFormBuilder
  def required?(attr)
    false
  end
  def errors_on?(attr)
    false
  end
end
