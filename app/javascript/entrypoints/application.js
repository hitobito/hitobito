// Copyright (c) 2026, Hitobito AG. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito.

// Referenced via "= javascript_include_tag 'application', 'data-turbo-track': true"
// in app/views/layouts/application.html.haml.

// Custom scripts from all wagons
import '../generated/wagon_scripts';

// Action Text
require("trix")
require("@rails/actiontext")

// prevent attaching files via drag and drop if the trix editor is nested below an element with class "no-attachments"
document.addEventListener('trix-file-accept', function(event) {
  if (event.target.closest('.no-attachments')) {
    event.preventDefault();
  }
});

// prevent attaching files via pasting if the trix editor is nested below an element with class "no-attachments"
document.addEventListener('trix-attachment-add', function(event) {
  if (event.target.closest('.no-attachments')) {
    event.attachment.remove();
  }
});
