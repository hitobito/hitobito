// Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
// hitobito_sac_cas and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito

import { Application } from "stimulus"
import { application } from "./application.js";

/**
 * Stimulus controllers within this directory
 */
import AutosubmitController from "./autosubmit_controller.js";
application.register("autosubmit_controller", AutosubmitController);

import FormFieldInheritanceController from "./form_field_inheritance_controller.js";
application.register("form_field_inheritance_controller", FormFieldInheritanceController);

import FormFieldToggleController from "./form_field_toggle_controller.js";
application.register("form_field_toggle_controller", FormFieldToggleController);

import ForwarderController from "./forwarder_controller.js";
application.register("forwarder_controller", ForwarderController);

import HelloController from "./hello_controller.js";
application.register("hello_controller", HelloController);

import RemoteAutocompleteController from "./remote_autocomplete_controller.js";
application.register("remote_autocomplete_controller", RemoteAutocompleteController);

import TomSelectController from "./tom_select_controller.js";
application.register("tom_select_controller", TomSelectController);

/**
 * Stimulus controllers within the components directory
 */
import StepsComponentController from "../../components/steps_component_controller.js";
application.register("steps_component_controller", StepsComponentController);
