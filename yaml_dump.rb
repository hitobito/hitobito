#!/usr/bin/env ruby

puts "reading .."
custom_contents = CustomContent.all.index_by(&:id)
custom_contents_data = custom_contents.values.map do |content|
  [content.key, content.attributes.transform_values(&:to_s).except(*%w[id created_at updated_at body]).compact_blank]
end.to_h.to_yaml

translations_data = CustomContent::Translation.find_each.map do |translation|
  content = custom_contents[translation.custom_content_id]
  key = [content.key, translation.locale].join("_")
  attrs = translation.attributes.transform_values(&:to_s).except(*%w[id created_at updated_at body])
  [key, attrs.merge(body: translation.body.to_s).stringify_keys.compact_blank]
end.to_h.to_yaml

def write(path, data)
  Rails.root.join("spec", "fixtures", path).write(data)
end

write("custom_contents.yml", custom_contents_data)
write("custom_content/translations.yml", translations_data)
