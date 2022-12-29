import { Application } from "@hotwired/stimulus"
import StimulusReflex from 'stimulus_reflex'

const application = Application.start()

// Configure Stimulus development experience
application.warnings = true
application.debug    = true
window.Stimulus      = application

// https://docs.stimulusreflex.com/appendices/troubleshooting
StimulusReflex.initialize(application, { debug: true })


export { application }
