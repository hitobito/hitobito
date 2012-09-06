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

Group::ProfessionalGroup::seed(:name, :parent_id,
  {name: 'FG Sicherheit',
   parent_id: states[0].id },
   
  {name: 'FG Security',
   parent_id: states[2].id },
)

Group::WorkGroup::seed(:name, :parent_id,
  {name: 'AG Bundeslager',
   parent_id: ch.id },
   
  {name: 'AG Kantonslager',
   parent_id: states[0].id },
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

Group::ChildGroup.seed(:name, :parent_id,
  {name: 'Asterix',
   parent_id: flocks[0].id },
   
  {name: 'Obelix',
   parent_id: flocks[0].id },
   
  {name: 'Idefix',
   parent_id: flocks[0].id },
   
  {name: 'Mickey',
   parent_id: flocks[1].id },
   
  {name: 'Minnie',
   parent_id: flocks[2].id },
   
  {name: 'Goofy',
   parent_id: flocks[3].id },
   
  {name: 'Donald',
   parent_id: flocks[4].id },
   
  {name: 'Gaston',
   parent_id: flocks[5].id },
   
  {name: 'Tim',
   parent_id: flocks[6].id },
   
  {name: 'Hadock',
   parent_id: flocks[7].id },
   
  {name: 'Batman',
   parent_id: flocks[8].id },
   
  {name: 'Robin',
   parent_id: flocks[8].id },
   
  {name: 'Spiderman',
   parent_id: flocks[9].id },
   
)

Group::SimpleGroup.seed(:name, :parent_id,
  {name: 'Tschutter',
   parent_id: flocks[0].id },
   
  {name: 'Angestellte',
   parent_id: states[0].id },
)
   
   
Group.rebuild!