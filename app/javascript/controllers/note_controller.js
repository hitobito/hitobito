import ApplicationController from './application_controller'

export default class extends ApplicationController {
  sayHi () {
    super.sayHi()
    console.log('Hello from a Custom controller')
  }
}
