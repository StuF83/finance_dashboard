import { Controller } from "@hotwired/stimulus";
import { Chart, registerables } from "chart.js";
Chart.register(...registerables);

export default class extends Controller {
  static targets = ["canvas"]
  static values = { 
    categories: Object,
    colors: Array
  }

  connect() {
    this.initializeChart()
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }

  initializeChart() {
    const ctx = this.canvasTarget.getContext('2d')
    const categoryData = this.categoriesValue
    const labels = Object.keys(categoryData)
    const amounts = labels.map(label => categoryData[label].amount)
    const percentages = labels.map(label => categoryData[label].percentage)
    const colors = this.colorsValue.slice(0, labels.length)

    this.chart = new Chart(ctx, {
      type: 'pie',
      data: {
        labels: labels,
        datasets: [{
          data: amounts,
          backgroundColor: colors,
          borderColor: '#fff',
          borderWidth: 2,
          hoverBorderWidth: 3
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom',
            labels: {
              padding: 20,
              usePointStyle: true
            }
          },
          tooltip: {
            callbacks: {
              label: (context) => {
                const label = context.label || ''
                const value = context.parsed
                const percentage = percentages[context.dataIndex]
                return `${label}: ${value.toLocaleString()} (${percentage}%)`
              }
            }
          }
        }
      }
    })
  }
}