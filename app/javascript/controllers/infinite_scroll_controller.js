import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.observer = new IntersectionObserver(this.handleIntersection.bind(this), {
      threshold: 0.1,
      rootMargin: '100px'
    })

    this.observer.observe(this.element)
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  handleIntersection(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting && this.urlValue) {
        this.loadMore()
      }
    })
  }

  async loadMore() {
    if (this.loading) return

    this.loading = true
    this.showLoading()

    try {
      const response = await fetch(this.urlValue, {
        headers: {
          'Accept': 'text/vnd.turbo-stream.html',
          'Turbo-Frame': 'zines-container'
        }
      })

      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)
      }
    } catch (error) {
      console.error('Error loading more zines:', error)
    } finally {
      this.loading = false
    }
  }

  showLoading() {
    const spinner = this.element.querySelector('.loading-spinner')
    if (spinner) {
      spinner.style.display = 'block'
    }
  }
}