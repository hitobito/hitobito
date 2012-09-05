ch = Group.roots.first

states = Group::State.seed(:name, :parent_id,
  {name: 'Kanton Bern',
   short_name: 'BE',
   parent_id: ch.id },

  {name: 'Kanton Zürich',
   short_name: 'ZH',
   parent_id: ch.id },
   
  {name: 'Kanton Nordost',
   short_name: 'NO',
   parent_id: ch.id },
)

regions = Group::Region.seed(:name, :parent_id,
  {name: 'Stadt',
   parent_id: states[0].id },
   
  {name: 'Oberland',
   parent_id: states[0].id },
   
  {name: 'Jura',
   parent_id: states[0].id },
   
  {name: 'Stadt',
   parent_id: states[1].id },
   
  {name: 'Oberland',
   parent_id: states[1].id },
)

flocks = Group::Flock.seed(:name, :parent_id,
  {name: 'Bern',
   parent_id: regions[0].id },
   
  {name: 'Muri',
   parent_id: regions[0].id },
   
  {name: 'Thun',
   parent_id: regions[1].id },
   
  {name: 'Interlaken',
   parent_id: regions[1].id },
   
  {name: 'Simmental',
   parent_id: regions[1].id },
   
  {name: 'Biel',
   parent_id: regions[2].id },
   
  {name: 'Chräis Chäib',
   parent_id: regions[3].id },
   
  {name: 'Wiedikon',
   parent_id: regions[3].id },
   
  {name: 'Innerroden',
   parent_id: states[2].id },
   
  {name: 'Ausserroden',
   parent_id: states[2].id },
)

Group.rebuild!