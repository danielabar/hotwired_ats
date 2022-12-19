import { Controller } from "@hotwired/stimulus"
// import { Controller } from 'stimulus'

export default class extends Controller {
  // https://stimulus.hotwired.dev/reference/values
  // We can reference these values in the controller with closeAfterValue
  // We can set a value on any instance of the controller in the DOM with data-[controller]-[valueName]-value.
  static values = {
    closeAfter: {
      type: Number,
      default: 2500
    },
    removeAfter: {
      type: Number,
      default: 1100
    },
  }

  // https://stimulus.hotwired.dev/reference/lifecycle-callbacks
  // lifecycle callbacks allow us to define behavior for controllers that will be executed each time a controller is added to or removed from the DOM
  // hide the toast container when the controller first enters the DOM
  initialize() {
    this.hide()
  }

  // https://stimulus.hotwired.dev/reference/lifecycle-callbacks
  // lifecycle callbacks allow us to define behavior for controllers that will be executed each time a controller is added to or removed from the DOM
  // automatically show (and then hide) the toast container every time the controller enters the DOM
  connect() {
    setTimeout(() => {
      this.show()
    }, 50)
    setTimeout(() => {
      this.close()
    }, this.closeAfterValue)
  }

  // Plain old JavaScript: Remove element from the viewport
  close() {
    this.hide()
    setTimeout(() => {
      this.element.remove()
    }, this.removeAfterValue)

  }

  // Plain old JavaScript: Transition element into the viewport
  show() {
    this.element.setAttribute(
      'style',
      "transition: 0.5s; transform:translate(0, -100px);",
      )
    }

  // Plain old JavaScript: Transition element out of the viewport
  hide() {
    this.element.setAttribute(
      'style',
      "transition: 1s; transform:translate(0, 200px);",
    )
  }
}
