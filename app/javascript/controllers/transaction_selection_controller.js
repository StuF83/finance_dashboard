// app/javascript/controllers/transaction_selection_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "actionsBar", 
    "selectedCount", 
    "bulkDeleteForm", 
    "transactionCheckbox", 
    "groupSelectAll"
  ]

  connect() {
    this.updateSelection()
    
    // Listen for window resize - simple approach that just clears selections
    this.boundHandleResize = this.handleViewChange.bind(this)
    window.addEventListener('resize', this.boundHandleResize)
  }

  disconnect() {
    window.removeEventListener('resize', this.boundHandleResize)
  }

  handleViewChange() {
    // Simple approach: just clear all selections when view changes
    // This prevents the confusion of having invisible selections
    setTimeout(() => {
      this.clearSelection()
    }, 150) // Small delay for CSS transitions
  }

  // Get only visible checkboxes (either desktop OR mobile, not both)
  getVisibleCheckboxes() {
    return this.transactionCheckboxTargets.filter(checkbox => {
      // Check if the checkbox is in a visible container
      const parentContainer = checkbox.closest('.transactions-table, .mobile-cards')
      if (!parentContainer) return true
      
      // Use getComputedStyle to check if the parent is actually visible
      const style = window.getComputedStyle(parentContainer)
      return style.display !== 'none'
    })
  }

  // Get visible checkboxes for a specific date group
  getVisibleCheckboxesForDate(date) {
    return this.getVisibleCheckboxes().filter(cb => cb.dataset.date === date)
  }

  // Called when individual transaction checkbox changes
  updateSelection() {
    const visibleCheckboxes = this.getVisibleCheckboxes()
    const selectedCheckboxes = visibleCheckboxes.filter(cb => cb.checked)
    const selectedCount = selectedCheckboxes.length
    
    // Show/hide actions bar
    if (selectedCount > 0) {
      this.actionsBarTarget.classList.add('show')
      this.selectedCountTarget.textContent = `${selectedCount} selected`
      this.updateBulkDeleteForm(selectedCheckboxes)
    } else {
      this.actionsBarTarget.classList.remove('show')
    }
    
    // Update group select-all checkboxes
    this.updateGroupSelectAllStates()
  }

  // Called when group "select all" checkbox changes
  toggleGroupAll(event) {
    const groupCheckbox = event.target
    const date = groupCheckbox.dataset.date
    const groupCheckboxes = this.getVisibleCheckboxesForDate(date)
    
    groupCheckboxes.forEach(checkbox => {
      checkbox.checked = groupCheckbox.checked
    })
    
    this.updateSelection()
  }

  // Clear all selections
  clearSelection() {
    const visibleCheckboxes = this.getVisibleCheckboxes()
    
    visibleCheckboxes.forEach(checkbox => {
      checkbox.checked = false
    })
    
    this.groupSelectAllTargets.forEach(checkbox => {
      checkbox.checked = false
      checkbox.indeterminate = false
    })
    
    this.updateSelection()
  }

  // Private methods
  updateBulkDeleteForm(selectedCheckboxes) {
    const form = this.bulkDeleteFormTarget
    
    // Remove existing hidden inputs
    const existingInputs = form.querySelectorAll('input[name="transaction_ids[]"]')
    existingInputs.forEach(input => input.remove())
    
    // Add selected transaction IDs to form (no duplicates)
    const addedIds = new Set() // Track added IDs to prevent duplicates
    
    selectedCheckboxes.forEach(checkbox => {
      const transactionId = checkbox.value
      
      // Only add if we haven't already added this ID
      if (!addedIds.has(transactionId)) {
        const hiddenInput = document.createElement('input')
        hiddenInput.type = 'hidden'
        hiddenInput.name = 'transaction_ids[]'
        hiddenInput.value = transactionId
        form.appendChild(hiddenInput)
        addedIds.add(transactionId)
      }
    })
  }

  updateGroupSelectAllStates() {
    this.groupSelectAllTargets.forEach(groupSelectAll => {
      const date = groupSelectAll.dataset.date
      const groupCheckboxes = this.getVisibleCheckboxesForDate(date)
      const checkedGroupCheckboxes = groupCheckboxes.filter(cb => cb.checked)
      
      if (checkedGroupCheckboxes.length === 0) {
        groupSelectAll.checked = false
        groupSelectAll.indeterminate = false
      } else if (checkedGroupCheckboxes.length === groupCheckboxes.length) {
        groupSelectAll.checked = true
        groupSelectAll.indeterminate = false
      } else {
        groupSelectAll.checked = false
        groupSelectAll.indeterminate = true
      }
    })
  }
}