// Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

import { Application, Controller } from "@hotwired/stimulus"
import { registerGeneratedControllers } from "../generated/controllers"

const stimulus = Application.start()

// Core controllers (this directory), component controllers and the controllers
// of every active wagon are registered explicitly by generated/controllers.js,
// which config/esbuild.mjs (re)writes on every build.
registerGeneratedControllers(stimulus)

export { Application, Controller, stimulus }
