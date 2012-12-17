quali_kinds = QualificationKind.seed(:label,
 {label: 'Experte',
  validity: 2},
  
 {label: 'Gruppenleitung',
  validity: 2},
  
 {label: 'Scharleitung',
  validity: 2}
)

Event::Kind.seed(:short_name,
 {label: 'Scharleiterkurs',
  short_name: 'SLK',
  qualification_kind_ids: [quali_kinds[2].id]},
  
 {label: 'Gruppenleiterkurs',
  short_name: 'GLK',
  qualification_kind_ids: [quali_kinds[1].id]},
  
 {label: 'Coachkurs',
  short_name: 'CK'}
)
