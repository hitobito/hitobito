const DropdownToggle = {

  get toggleLinks() {
    return document
      .querySelectorAll('.dropdown-menu li.dropend a.dropdown-toggle');
  },

  get submenus() {
    return document
      .querySelectorAll('.dropdown-menu .dropdown-menu');
  },

  hideAllSubmenus() {
    this.submenus.forEach((m) => {
      m.style.display = 'none';
    })
  },

  // enable submenu toggle by mouseover since this is not supported by
  // bootstrap 5 anymore
  register() {
    // TODO hide all submenus when top dropdown-menu closes
    this.toggleLinks.forEach((l) => {
      l.addEventListener('mouseover', (e) => {
        this.hideAllSubmenus();
        const el = e.target.nextElementSibling;
        el.style.display = el.style.display === 'block' ? 'none' : 'block';
      })
      l.addEventListener('mouseout', (e) => {
        // this.hideAllSubmenus();
      })
    })
  }
}

document.addEventListener("DOMContentLoaded",
    () => DropdownToggle.register());
