import ApplicationController from './application_controller'
import Sortable from 'sortablejs'

export default class extends ApplicationController {
  static targets = [ 'list' ]
  static values = {
    attribute: String,
    resource: String
  }

  connect () {
    super.connect()
    this.listTargets.forEach(this.initializeSortable.bind(this))
  }

  initializeSortable(target) {
    new Sortable(target, {
      group: 'shared',
      animation: 100,
      sort: false,
      onEnd: this.end.bind(this)
    })
  }

  end(event) {
    const value = event.to.dataset.newValue
    this.stimulate(
      "Draggable#update_record",
      event.item,
      this.resourceValue,
      this.attributeValue,
      value
    )
  }
}