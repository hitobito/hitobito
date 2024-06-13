// Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
// hitobito_sac_cas and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

import { Application } from "stimulus"

export const stimulus = Application.start()

/**
 * Stimulus controllers within this directory
 */
import ApplicationController from "./application.js";
stimulus.register("application", ApplicationController);

import AutosubmitController from "./autosubmit_controller.js";
stimulus.register("autosubmit_controller", AutosubmitController);

import FormFieldInheritanceController from "./form_field_inheritance_controller.js";
stimulus.register("form_field_inheritance_controller", FormFieldInheritanceController);

import FormFieldToggleController from "./form_field_toggle_controller.js";
stimulus.register("form_field_toggle_controller", FormFieldToggleController);

import ForwarderController from "./forwarder_controller.js";
stimulus.register("forwarder_controller", ForwarderController);

import HelloController from "./hello_controller.js";
stimulus.register("hello_controller", HelloController);

import RemoteAutocompleteController from "./remote_autocomplete_controller.js";
stimulus.register("remote_autocomplete_controller", RemoteAutocompleteController);

import TomSelectController from "./tom_select_controller.js";
stimulus.register("tom_select_controller", TomSelectController);

/**
 * Stimulus controllers within the components directory
 */
import StepsComponentController from "../../components/steps_component_controller.js";
stimulus.register("steps_component_controller", StepsComponentController);
