# follow conventions of http://jsonapi.org/

json.set! :people do
  json.array!([@person]) do |person|
    json.extract!(person, :id,
                          :first_name, 
                          :last_name,
                          :nickname, 
                          :company_name,
                          :company,
                          :gender,
                          :primary_group_id,
                          :email, 
                          :authentication_token,
                          :last_sign_in_at,
                          :current_sign_in_at)
     
    json.href person_home_path(@person, only_path: false, format: :json)
  end
end