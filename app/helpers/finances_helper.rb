module FinancesHelper
  def category_icon(category)
    icons = {
      "Groceries" => "🛒",
      "Transport" => "🚗",
      "Bills" => "🏠",
      "Entertainment" => "🎬",
      "Restaurants" => "🍽️",
      "Shopping" => "🛍️",
      "Healthcare" => "🏥",
      "Education" => "📚",
      "Travel" => "✈️",
      "Salary" => "💰",
      "Investment" => "📈",
      "Other" => "📊",
      "Uncategorized" => "❓"
    }

    # Try exact match first, then partial match, then default
    icon = icons[category] ||
           icons.find { |key, _| category.downcase.include?(key.downcase) }&.last ||
           "📊"

    icon
  end

  def chart_color(index)
    colors = [
      "#FF6384", "#36A2EB", "#FFCE56", "#4BC0C0",
      "#9966FF", "#FF9F40", "#FF6384", "#C9CBCF",
      "#4BC0C0", "#FF6384", "#36A2EB", "#FFCE56"
    ]
    colors[index % colors.length]
  end

  def category_chart_colors
  [
      "#e74c3c", # Red
      "#3498db", # Blue
      "#2ecc71", # Green
      "#f39c12", # Orange
      "#9b59b6", # Purple
      "#1abc9c", # Turquoise
      "#34495e", # Dark Gray
      "#e67e22", # Dark Orange
      "#16a085", # Dark Turquoise
      "#8e44ad", # Dark Purple
      "#2980b9", # Dark Blue
      "#27ae60"  # Dark Green
  ]
  end

  def format_currency(amount)
    "£#{number_with_delimiter(amount, delimiter: ",")}"
  end

  def transaction_type_color(type)
    case type
    when "expense"
      "text-red-600"
    when "income"
      "text-green-600"
    else
      "text-gray-600"
    end
  end
end
