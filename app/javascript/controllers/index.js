// Load all the controllers within this directory and all subdirectories.
// Controller files must be named *_controller.js.

import { Application } from "stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"
import { Controller } from "@hotwired/stimulus"

const stimulus = Application.start()

const ctrlContext = require.context("controllers", true, /_controller\.js$/)
stimulus.load(definitionsFromContext(ctrlContext))

const compContext = require.context('../../components', true, /\_controller.js$/)
stimulus.load(definitionsFromContext(compContext))
export { Application, Controller, stimulus, definitionsFromContext }
