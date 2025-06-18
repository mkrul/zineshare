import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  filterChanged(event) {
    const selectedCategory = event.target.value
    const url = new URL(window.location)

    if (selectedCategory === 'all') {
      url.searchParams.delete('category_id')
    } else {
      url.searchParams.set('category_id', selectedCategory)
    }

    // Reset to page 1 when filtering
    url.searchParams.delete('page')

    // Navigate to the new URL
    Turbo.visit(url.toString())
  }
}