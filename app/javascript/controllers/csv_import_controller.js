import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fileInput"]
  
  // Action: triggered when import button is clicked
  triggerFileInput() {
    this.fileInputTarget.click()
  }
  
  // Action: triggered when file is selected
  handleFileChange(event) {
    if (event.target.files.length > 0) {
      event.target.form.submit()
    }
  }
}