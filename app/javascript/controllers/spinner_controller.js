import { Controller } from "@hotwired/stimulus"

// Connects to elements with data-controller="spinner"
// Automatically detects AJAX vs regular links and shows loading state
// Uses Turbo events (turbo:submit-start, turbo:submit-end) for form submissions
//
// Usage:
//   AJAX form button (icon replacement) - Turbo intercepts automatically:
//     <form method="post" action="/submit">
//       <button data-controller="spinner" data-remote="true">Submit</button>
//     </form>
//
//   AJAX link (icon replacement):
//     <a href="..." data-controller="spinner" data-remote="true">Link</a>
//
//   With spinner target (child element):
//     <button data-controller="spinner" data-remote="true">
//       <span data-spinner-target="spinnerElement">Loading...</span>
//       Submit
//     </button>
//
//   With external spinner (selector value):
//     <button data-controller="spinner" data-remote="true"
//             data-spinner-selector-value="#my-spinner">Submit</button>
//
//   Normal (non-AJAX) link - shows spinner before navigation:
//     <a href="/page" data-controller="spinner">Go to page</a>
//
//   Download link with auto-hide timeout (page doesn't navigate):
//     <a href="/download.pdf" data-controller="spinner" data-spinner-timeout-value="2000">Download</a>
export default class extends Controller {
  static targets = ["spinnerElement"]
  static values = {
    selector: String,        // Optional: CSS selector for external spinner
    originalIconClass: String,  // Stores original icon class for restoration
    timeout: Number          // Optional: Auto-hide spinner after X milliseconds (useful for downloads)
  }

  connect() {
    // Auto-detect if this is an AJAX link and add appropriate Stimulus actions
    const isAjax = this.element.dataset.remote !== undefined

    if (isAjax) {
      this.setupAjaxActions()
    } else if (this.element.tagName === 'A') {
      this.setupNormalLinkActions()
    }
  }

  // Setup Stimulus actions for AJAX links
  // Listen on @window to catch Turbo events bubbling up from parent forms
  setupAjaxActions() {
    this.element.dataset.action = this.addAction(
      this.element.dataset.action,
      'turbo:submit-start@window->spinner#show turbo:submit-end@window->spinner#hide'
    )
  }

  // Setup Stimulus actions for normal (non-AJAX) links

  setupNormalLinkActions() {
    this.element.dataset.action = this.addAction(
      this.element.dataset.action,
      'click->spinner#handleClick'
    )
  }

  // Helper to merge actions without duplicates
  addAction(existingActions, newActions) {
    if (!existingActions) return newActions

    const existing = existingActions.split(' ').filter(a => a.length > 0)
    const toAdd = newActions.split(' ').filter(a => a.length > 0)

    return [...new Set([...existing, ...toAdd])].join(' ')
  }

  // Handle click on normal (non-AJAX) links
  handleClick(e) {
    e.preventDefault()
    this.show()

    // Navigate after short delay to show spinner
    setTimeout(() => {
      window.location.href = this.element.href
    }, 200)

    // If timeout value is set, auto-hide spinner after specified duration
    // This is useful for download links where the page doesn't navigate away
    if (this.hasTimeoutValue) {
      setTimeout(() => {
        this.hide()
      }, this.timeoutValue)
    }
  }

  // Show spinner and disable button
  show() {
    this.element.disabled = true
    this.element.classList.add('disabled')

    const spinner = this.getSpinner()
    if (spinner) {
      spinner.style.display = ''
    } else {
      this.replaceIconWithSpinner()
    }
  }

  // Hide spinner and re-enable button
  hide() {
    this.element.disabled = false
    this.element.classList.remove('disabled')

    // First check if we replaced an icon
    if (this.hasOriginalIconClassValue) {
      this.restoreOriginalIcon()
    } else {
      // Otherwise, hide external spinner
      const spinner = this.getSpinner()
      if (spinner) {
        spinner.style.display = 'none'
      }
    }
  }

  // Get the spinner element
  // Priority: 1) target, 2) selector value, 3) find child/sibling
  getSpinner() {
    // 1. Check if we have a target
    if (this.hasSpinnerElementTarget) {
      return this.spinnerElementTarget
    }

    // 2. Check if we have a selector value
    if (this.hasSelectorValue) {
      return document.querySelector(this.selectorValue)
    }

    // 3. Find siblings of the button element (matches CoffeeScript: button.siblings('.spinner'))
    const parent = this.element.parentElement
    if (parent) {
      // Find .spinner elements that are siblings of this.element
      const siblings = Array.from(parent.children).filter(
        child => child !== this.element && child.classList.contains('spinner')
      )
      if (siblings.length > 0) return siblings[0]
    }

    return null
  }

  // Get the icon element
  getIcon() {
    return this.element.querySelector('i.fas, i.far, i.fab, i.fal')
  }

  // Replace the button's icon with a spinner icon
  // Stores the original icon class for restoration later
  replaceIconWithSpinner() {
    const icon = this.getIcon()
    if (icon) {
      // Store original classes in Stimulus value
      this.originalIconClassValue = icon.className
      // Replace with spinner
      icon.className = 'fas fa-spinner fa-spin'
    }
  }

  // Restore the button's original icon
  restoreOriginalIcon() {
    const icon = this.getIcon()
    if (icon) {
      // Restore the original icon from Stimulus value
      icon.className = this.originalIconClassValue
      this.originalIconClassValue = ''
    }
  }
}
