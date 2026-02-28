// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "trix"

// Open all rich-text display links in a new tab
function patchTrixLinks() {
  document.querySelectorAll(".trix-content a[href]").forEach(a => {
    a.target = "_blank"
    a.rel    = "noopener noreferrer"
  })
}
document.addEventListener("turbo:load",   patchTrixLinks)
document.addEventListener("turbo:render", patchTrixLinks)
