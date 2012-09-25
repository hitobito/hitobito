filters = PeopleFilter.seed(:group_type, :name,
 {name: 'Scharleiter',
  group_type: 'Group::State',
  kind: 'deep'},
  
 {name: 'Präses',
  group_type: 'Group::State',
  kind: 'deep'},
  
 {name: 'Scharleiter',
  group_type: 'Group::Region',
  kind: 'deep'},
  
 {name: 'Präses',
  group_type: 'Group::Region',
  kind: 'deep'}
)

PeopleFilter::RoleType.seed_once(:people_filter_id, :role_type,
 {people_filter_id: filters[0].id,
  role_type: 'Group::Flock::Leader'},
  
 {people_filter_id: filters[1].id,
  role_type: 'Group::Flock::President'},
  
 {people_filter_id: filters[2].id,
  role_type: 'Group::Flock::Leader'},
  
 {people_filter_id: filters[3].id,
  role_type: 'Group::Flock::President'},
)