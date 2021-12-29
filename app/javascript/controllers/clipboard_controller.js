import ApplicationController from './application_controller.js'

export default class extends ApplicationController {
  copy (event) {
    event.preventDefault()
    navigator.clipboard.writeText(event.params.text)
  }
}
