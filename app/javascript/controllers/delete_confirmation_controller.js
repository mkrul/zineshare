import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "form", "title", "message"]
  static values = {
    title: String,
    message: String,
    action: String,
    method: String
  }

  connect() {
    this.boundCloseOnEscape = this.closeOnEscape.bind(this)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundCloseOnEscape)
  }

  show(event) {
    event.preventDefault()

    const button = event.currentTarget
    const url = button.dataset.url || button.href
    const title = button.dataset.confirmTitle || button.dataset["confirm-title"] || this.titleValue || "Confirm Action"
    const message = button.dataset.confirmMessage || button.dataset["confirm-message"] || this.messageValue || "Are you sure?"



    // Store the action details
    this.actionValue = url
    this.methodValue = button.dataset.turboMethod || button.dataset["turbo-method"] || "delete"

    // Update modal content
    this.titleTarget.textContent = title
    this.messageTarget.textContent = message

    // Show modal
    this.modalTarget.classList.add("show")
    document.body.classList.add("modal-open")
    document.addEventListener("keydown", this.boundCloseOnEscape)

    // Focus the cancel button for accessibility
    const cancelButton = this.modalTarget.querySelector('[data-action*="cancel"]')
    if (cancelButton) cancelButton.focus()
  }

  confirm() {
    if (!this.actionValue) {
      console.error("No action URL available for delete confirmation")
      return
    }

    // Create a form and submit it using Turbo
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = this.actionValue
    form.style.display = 'none'

    // Add CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    if (csrfToken) {
      const csrfInput = document.createElement('input')
      csrfInput.type = 'hidden'
      csrfInput.name = 'authenticity_token'
      csrfInput.value = csrfToken
      form.appendChild(csrfInput)
    }

    // Add method override for DELETE
    const methodInput = document.createElement('input')
    methodInput.type = 'hidden'
    methodInput.name = '_method'
    methodInput.value = 'DELETE'
    form.appendChild(methodInput)

    // Append form to body and submit
    document.body.appendChild(form)
    form.submit()

    this.close()
  }

  cancel() {
    this.close()
  }

  close() {
    this.modalTarget.classList.remove("show")
    document.body.classList.remove("modal-open")
    document.removeEventListener("keydown", this.boundCloseOnEscape)
  }

  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  // Close modal when clicking backdrop
  closeOnBackdrop(event) {
    if (event.target === this.modalTarget) {
      this.close()
    }
  }
}