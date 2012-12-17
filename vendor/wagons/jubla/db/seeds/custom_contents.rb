CustomContent.seed_once(:key,

  {key: CensusMailer::CONTENT_INVITATION,
   label: 'Bestandesmeldung: E-Mail Aufruf',
   subject: 'Bestandesmeldung ausfüllen',
   body: "Hallo!<br/><br/>Auch dieses Jahr erheben wir die aktuellen Mitgliederzahlen. Wir bitten dich, den Bestand deiner Gruppe zu aktualisieren und die Bestandesmeldung bis am {due-date} zu bestätigen.<br/><br/>Vielen Dank für deine Mithilfe.<br/><br/>Deine Jubla",
   placeholders_optional: 'due-date'},
   
  {key: CensusMailer::CONTENT_REMINDER,
   label: 'Bestandesmeldung: E-Mail Erinnerung',
   subject: 'Bestandesmeldung ausfüllen!',
   body: "Hallo {recipient-names}<br/><br/>Wir bitten dich, den Bestand deiner Gruppe zu aktualisieren und die Bestandesmeldung bis am {due-date} zu bestätigen:<br/><br/>{census-url}<br/><br/>Vielen Dank für deine Mithilfe. Bei Fragen kannst du dich an die folgende Adresse wenden:<br/><br/>{contact-address}<br/><br/>Deine Jubla",
   placeholders_optional: 'recipient-names, due-date, contact-address, census-url'},
   
)

