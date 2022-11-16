const DropdownToggle = {

  get toggleLinks() {
    return document
      .querySelectorAll('.dropdown-menu li.dropend a.dropdown-toggle');
  },

  // enable submenu toggle by mouseover since this is not supported by
  // bootstrap 5 anymore
  register() {
    this.toggleLinks.forEach((l) => {
      l.addEventListener('mouseover', function (e) {
          const el = this.nextElementSibling;
          el.style.display = el.style.display === 'block' ? 'none' : 'block';
      })
      l.addEventListener('mouseout', function (e) {
          const el = this.nextElementSibling;
          el.style.display = el.style.display === 'block' ? 'block' : 'none';
      })
    })
  }
}

document.addEventListener("DOMContentLoaded",
    () => DropdownToggle.register());
