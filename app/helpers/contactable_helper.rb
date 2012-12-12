module ContactableHelper
  def info_field_set_tag(legend=nil, options={}, &block)
    if entry.is_a?(Group)
      opts = { class: 'info' }
      opts.merge!(entry.contact ? { style: 'display: none' } : {})
      field_set_tag(legend, options.merge(opts), &block)
    else
      field_set_tag(legend, options, &block)
    end
  end
end
