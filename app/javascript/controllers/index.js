// Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

import { Application } from "stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"
import { Controller } from "@hotwired/stimulus"
import { registerGeneratedControllers } from "./generated_index"

const stimulus = Application.start()

// Core controllers (this directory) and wagon controllers (from *every
// active* wagon, per tmp/wagon_assets_manifest.json - see
// lib/tasks/assets.rake) are registered explicitly by generated_index.js,
// which esbuild.config.js (re)writes on every build. This replaces the
// dynamic require.context sweep webpack used to do here.
registerGeneratedControllers(stimulus)

export { Application, Controller, stimulus, definitionsFromContext }
