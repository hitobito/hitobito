// Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

import { Application } from "stimulus"
import { definitionsFromContext, definitionForModuleAndIdentifier } from "stimulus/webpack-helpers"
import { Controller } from "@hotwired/stimulus"

const stimulus = Application.start()

// Load all the controllers within this directory and all subdirectories.
const ctrlContext = require.context("controllers", true, /_controller\.js$/)
stimulus.load(definitionsFromContext(ctrlContext))

// Load all the controllers from components
const compContext = require.context('../../components', true, /\_controller.js$/)
stimulus.load(definitionsFromContext(compContext))

function definitionsFromWagonContext(context) {
  return context.keys()
    .map((key) => {
      const wagonName = key.match(/\bhitobito_([^/]+)\//)
      const controllerName = key.split("/").pop().match(/^(.+)_controller\.js$/)

      return definitionForModuleAndIdentifier(context(key), `${wagonName[1].replace(/_/g, "-")}--${controllerName[1].replace(/_/g, "-")}`)
    })
}

// WEBPACK_SIBLING_WAGONS is set at compile time by DefinePlugin in environment.js.
// It is true when wagon directories are mounted as siblings (local dev/test) and
// false when they have been moved to vendor/wagons (CI test and Docker production
// builds). webpack dead-code-eliminates the unused branch, so the broad ../../../../
// context is never evaluated where it would scan the filesystem root.
if (WEBPACK_SIBLING_WAGONS) {
  const devWagonCtrlContext = require.context(
    "../../../../",
    true,
    /\bhitobito_[^/]+\/app\/javascript\/controllers\/.*_controller\.js$/
  )
  stimulus.load(definitionsFromWagonContext(devWagonCtrlContext))
} else {
  const prodWagonCtrlContext = require.context(
    "../../../",
    true,
    /\bvendor\/wagons\/hitobito_[^/]+\/app\/javascript\/controllers\/.*_controller\.js$/
  )
  stimulus.load(definitionsFromWagonContext(prodWagonCtrlContext))
}

export { Application, Controller, stimulus, definitionsFromContext }
