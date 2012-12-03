module CustomContentsHelper
  def format_custom_content_body(content)
    strip_tags(content.body).to_s.truncate(100)
  end
end