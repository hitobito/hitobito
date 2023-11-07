// frozen_string_literal: true
//
//  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
//  hitobito and licensed under the Affero General Public License version 3
//  or later. See the COPYING file at the top-level directory or at
//  https://github.com/hitobito/hitobito.

import { Controller } from "controllers"

export default class extends Controller {

  activate(event) {
    event.preventDefault()
    event.stopPropagation()
    const index = this.getIndex(event.target.parentElement);
    this.activateStep(index)
  }

  activateStep(index) {
    const headers = Array.from(this.element.querySelectorAll('ol.step-headers li'))
    const contents = Array.from(this.element.querySelectorAll('.step-content'))

    headers.forEach(elem => elem.classList.remove('active'))
    contents.forEach(elem => elem.classList.remove('active'))

    headers[index].classList.add('active')
    contents[index].classList.add('active')
  }

  getIndex(element) {
    return Array.from(element.parentNode.children).indexOf(element);
  }

  back(event) {
    event.preventDefault()
    const index = parseInt(event.target.dataset['index'])
    this.activateStep(index)
  }
}
