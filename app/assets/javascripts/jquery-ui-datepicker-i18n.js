jQuery(function () {
 
    $.datepicker.regional["en"] = {}, //datepicker defaults are in English!
 
    $.datepicker.regional['de'] = {
        closeText:   "Schliessen",
        prevText:    "Voriger Monat",
        nextText:    "Nächster Monat",
        currentText: "Heute",
        monthNames: ["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli",
                     "A", "September", "Oktober", "November", "Dezember"],
        monthNamesShort:["Janv.", "Févr.", "Mars", "Avril", "Mai", "Juin",
                         "Juil.", "Août", "Sept.", "Oct.", "Nov.", "Déc."],
        dayNames:   ["Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag"],
        dayNamesShort: ["So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"],
        dayNamesMin:   ["So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"],
        weekHeader:    "W",
        dateFormat:    "dd.mm.yy",
        firstDay: 1,
    },
     //set our default locale
    $.datepicker.setDefaults($.datepicker.regional["de"]);
})