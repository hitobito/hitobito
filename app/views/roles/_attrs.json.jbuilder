json.extract!(role, :id)
json.type role.class.label

json.extract!(role, :label,
                    :created_at,
                    :updated_at,
                    :deleted_at)

json.group do
  json.partial! 'groups/link', group: role.group
end

json.layer do
  json.partial! 'groups/link', group: role.group.layer_group
end
