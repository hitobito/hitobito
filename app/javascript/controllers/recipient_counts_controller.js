import ApplicationController from './application_controller.js'

export default class extends ApplicationController {
  connect () {
    super.connect()

    this.loadCount()
  }

  loadCount () {
    if (this.isActionCableConnectionOpen()) {
      this.stimulate('MailingLists::RecipientCounts#init_count', this.scope.element.value)
    }
    else {
      setTimeout(function () {
        this.loadCount();
      }.bind(this), 100)
    }
  }
}
