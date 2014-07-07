if group
  json.id   group.id
  json.href group_url(group, format: :json)
  json.name group.to_s
  json.type group.class.label
else
  json.null!
end