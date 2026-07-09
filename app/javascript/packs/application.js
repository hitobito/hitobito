// Copyright (c) 2026, Hitobito AG. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito.

// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

// To reference this file, add "= javascript_pack_tag 'application', 'data-turbo-track': true"
// to the appropriate layout file, like app/views/layouts/application.html.erb

// Gems without NPM package
import '../javascripts/vendor/gems';

// Custom scripts from all wagons
import '../javascripts/wagons';

// Images
const images = require.context('../images', true);
const imagePath = (name) => images(name, true);

// Action Text
require("trix")
require("@rails/actiontext")
// prevent adding attachments via drag and drop
document.addEventListener('trix-file-accept', function(event) {
  if(event.target.parentNode.parentNode.classList.contains('no-attachments')) {
    event.preventDefault();
  }
});
