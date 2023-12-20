// Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
// hitobito_sac_cas and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

import { Application } from "stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"
import { Controller } from "@hotwired/stimulus"

const stimulus = Application.start()

// Load all the controllers within this directory and all subdirectories.
const ctrlContext = require.context("controllers", true, /_controller\.js$/)
stimulus.load(definitionsFromContext(ctrlContext))

// Load all the controllers from components
const compContext = require.context('../../components', true, /\_controller.js$/)
stimulus.load(definitionsFromContext(compContext))
export { Application, Controller, stimulus, definitionsFromContext }
