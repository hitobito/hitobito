// Copyright (c) 2026, BdP and DPSG. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

import NestedForm from "@stimulus-components/rails-nested-form/dist/stimulus-rails-nested-form.umd.js"

export default class extends NestedForm {
  connect() {
    super.connect()
    console.log("Do what you want here.")
  }
}
