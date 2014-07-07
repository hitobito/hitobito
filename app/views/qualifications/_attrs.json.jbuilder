json.id qualification.id
json.kind qualification.qualification_kind.to_s
json.extract!(qualification, :start_at,
                             :finish_at,
                             :origin)
