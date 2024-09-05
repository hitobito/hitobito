import { Controller } from "stimulus"
import * as WebAuthnJSON from "@github/webauthn-json"
import { FetchRequest } from "@rails/request.js"

export default class extends Controller {
  static targets = ["nickname"]
  static values = { callback: String }

  create(event) {
    const [data, status, xhr] = event.detail;
    const _this = this

    WebAuthnJSON.create({ "publicKey": data }).then(async function(credential) {
      const request = new FetchRequest("post", _this.callbackValue + `?nickname=${_this.nicknameTarget.value}`, { body: JSON.stringify(credential), responseKind: "turbo-stream" })
      await request.perform()
    }).catch(function(error) {
      console.log("something is wrong", error);
    });
  }

  error(event) {
    console.log("something is wrong", event);
  }
}
