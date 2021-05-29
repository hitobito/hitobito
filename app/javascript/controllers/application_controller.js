import { Controller } from 'stimulus'
import StimulusReflex from 'stimulus_reflex'

export default class extends Controller {
  connect () {
    StimulusReflex.register(this)
  }
  sayHi () {
    console.log('Hello from the Application controller.')
  }
}
