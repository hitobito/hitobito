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

// Load all the controllers from wagons for local dev setup
const devWagonCtrlContext = require.context(
  "../../../../",
  true,
  /\bhitobito_[^/]+\/app\/javascript\/controllers\/.*_controller\.js$/
)
stimulus.load(definitionsFromWagonContext(devWagonCtrlContext))

// Load all the controllers from wagons for prod
const prodWagonCtrlContext = require.context(
  "../../../",
  true,
  /\bvendor\/wagons\/hitobito_[^/]+\/app\/javascript\/controllers\/.*_controller\.js$/
)
stimulus.load(definitionsFromWagonContext(prodWagonCtrlContext))

export { Application, Controller, stimulus, definitionsFromContext }
