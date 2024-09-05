import AuthController from "./auth_controller"

export default class extends AuthController {
  static targets = ["email", "password", "default", "webauthn"]
  static values = {
    callback: String,
    webauthn: String
  }

  connect() {
    this.webauthn = true
    this.defaultActionUrl = this.element.getAttribute("action")
  }

  toggle(event) {
    event.preventDefault()
    this.passwordTarget.classList.toggle("hidden")
    this.defaultTarget.classList.toggle("hidden")
    this.webauthnTarget.classList.toggle("hidden")

    if(this.webauthn) {
      this.element.setAttribute("data-remote", true)
      this.element.setAttribute("data-turbo", false)
      this.element.setAttribute("action", this.webauthnValue)
    } else {
      this.element.setAttribute("data-remote", false)
      this.element.setAttribute("data-turbo", true)
      this.element.setAttribute("action", this.defaultActionUrl)
    }

    this.webauthn = !this.webauthn
  }
}
