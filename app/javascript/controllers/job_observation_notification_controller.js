// Copyright (c) 2026, Hitobito AG. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito.

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    generatedFileDownloadUrl: String
  }

  connect() {
    if(this.generatedFileDownloadUrlValue) {
      this.downloadGeneratedFile(this.generatedFileDownloadUrlValue);
    }

    const toast = new Toast(this.element);
    toast.show();
  }

  // If we were to use window.location.href there could only ever be one toast on the page
  // at a time because the page navigation causes previous toasts to vanish
  downloadGeneratedFile(url) {
    const link = document.createElement('a');

    link.href = url;
    link.setAttribute('download', '');

    document.body.appendChild(link);

    link.click();

    link.remove();
  }
}
