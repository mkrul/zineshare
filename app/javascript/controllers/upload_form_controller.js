import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submitButton", "cancelButton", "fileInput", "errorModal"]

    connect() {
    this.form = this.element
    this.originalSubmitText = this.submitButtonTarget.textContent
    this.boundCloseOnEscape = this.closeOnEscape.bind(this)
    this.boundHandleButtonClick = this.handleButtonClick.bind(this)

    // Add click handler to submit button for immediate feedback
    this.submitButtonTarget.addEventListener('click', this.boundHandleButtonClick)
  }

  disconnect() {
    if (this.submitButtonTarget) {
      this.submitButtonTarget.removeEventListener('click', this.boundHandleButtonClick)
    }
    document.removeEventListener("keydown", this.boundCloseOnEscape)
  }

    // Handle button click for immediate visual feedback
  handleButtonClick(event) {
    // Small delay to allow form validation, then disable button
    setTimeout(() => {
      if (this.validateForm()) {
        this.disableButton()
      }
    }, 50)
  }

  // Handle regular form submission for validation
  handleSubmit(event) {
    if (!this.validateForm()) {
      event.preventDefault()
      return false
    }
    // Loading state already shown by button click handler
  }

  // Handle Turbo form submission events
  turboSubmitStart(event) {
    this.disableButton()
  }

  turboSubmitEnd(event) {
    // Check for errors in the response
    if (this.form.querySelector('.error-messages')) {
      this.enableButton()
      // Don't show error modal for validation errors - they're displayed inline
    }
    // If successful, button stays disabled as user will be redirected
  }

  // Disable button
  disableButton() {
    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.classList.add('btn-disabled')
  }

  // Enable button (for error cases)
  enableButton() {
    this.submitButtonTarget.disabled = false
    this.submitButtonTarget.classList.remove('btn-disabled')
  }

  // Validate form before submission - only check for obvious issues
  validateForm() {
    // Only prevent submission if absolutely no data is provided
    // Let Rails handle the detailed validation and error messages
    const fileInput = this.hasFileInputTarget ? this.fileInputTarget : this.form.querySelector('input[type="file"]')
    const title = this.form.querySelector('input[name="zine[title]"]')
    const createdBy = this.form.querySelector('input[name="zine[created_by]"]')
    const category = this.form.querySelector('select[name="zine[category_id]"]')

    // Allow form submission - let Rails validation handle the details
    // This way users can see proper validation messages
    return true
  }

  // Error modal methods
  showErrorModal() {
    this.errorModalTarget.classList.add("show")
    document.body.classList.add("modal-open")
    document.addEventListener("keydown", this.boundCloseOnEscape)

    // Focus the "Try Again" button for accessibility
    const tryAgainButton = this.errorModalTarget.querySelector('[data-action*="closeErrorModal"]')
    if (tryAgainButton) tryAgainButton.focus()
  }

  closeErrorModal() {
    this.errorModalTarget.classList.remove("show")
    document.body.classList.remove("modal-open")
    document.removeEventListener("keydown", this.boundCloseOnEscape)
  }

  closeErrorModalOnBackdrop(event) {
    if (event.target === this.errorModalTarget) {
      this.closeErrorModal()
    }
  }

  closeOnEscape(event) {
    if (event.key === 'Escape' && this.errorModalTarget.classList.contains("show")) {
      this.closeErrorModal()
    }
  }
}