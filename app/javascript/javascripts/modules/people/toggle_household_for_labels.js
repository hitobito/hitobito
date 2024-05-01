$(document).on("click", "#toggle-household-labels", function (event) {
  event.stopImmediatePropagation();
  $(this).find('input[type="checkbox"]').toggle;
});

$(document).on(
  "change",
  '#toggle-household-labels input[type="checkbox"]',
  function (event) {
    let param = "household=";
    let checked = !!this.checked;
    $(this)
      .parents(".dropdown-menu")
      .find("a.export-label-format")
      .each(function () {
        $(this).attr(
          "href",
          $(this)
            .attr("href")
            .replace(param + !checked, param + checked)
        );
      });
  }
);
