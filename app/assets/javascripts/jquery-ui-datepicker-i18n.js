jQuery(function () {
 
    $.datepicker.regional["en"] = {}, //datepicker defaults are in English!
 
    $.datepicker.regional['de'] = {
        closeText:   "Schliessen",
        prevText:    "Voriger Monat",
        nextText:    "Nächster Monat",
        currentText: "Heute",
        monthNames: ["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli",
                     "August", "September", "Oktober", "November", "Dezember"],
        monthNamesShort:["Jan", "Feb", "Mär", "Apr", "Mai", "Jun",
                         "Jul", "Aug", "Sep", "Okt", "Nov", "Dez"],
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