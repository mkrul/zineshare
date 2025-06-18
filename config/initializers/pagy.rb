# Pagy initializer file
require 'pagy'
require 'pagy/extras/overflow'
require 'pagy/extras/headers'

# Instance variables
# See https://ddnexus.github.io/pagy/docs/api/pagy#instance-variables
Pagy::DEFAULT[:page]   = 1
Pagy::DEFAULT[:items]  = 12  # Items per page for good grid layout
Pagy::DEFAULT[:outset] = 0

# Overflow extra: Allow empty page navigation
# See https://ddnexus.github.io/pagy/docs/extras/overflow
Pagy::DEFAULT[:overflow] = :empty_page

# Headers extra: Useful for API responses
# See https://ddnexus.github.io/pagy/docs/extras/headers
# Pagy::DEFAULT[:headers] = { page: 'Current-Page', items: 'Page-Items', count: 'Total-Count', pages: 'Total-Pages' }