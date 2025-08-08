class FinancesController < ApplicationController
  def index
    # Get current month's date range
    start_of_month = Date.current.beginning_of_month
    end_of_month = Date.current.end_of_month

    # Calculate summary statistics for current month
    @total_income = Transaction.total_income(start_of_month, end_of_month)
    @total_expenses = Transaction.total_expenses(start_of_month, end_of_month)
    @net_balance = @total_income - @total_expenses

    # Get recent transactions (last 10)
    @recent_transactions = Transaction.recent.limit(10)
  end

    def import
    begin

      # Handle file upload or retrieve from session
      file_path = get_file_path

      return if file_path.nil? # Redirected with error
      # Determine if this is scan or force proceed request
      options = params[:force_proceed] == "true" ? { force_proceed: true } : {}

      # Call the import service
      @results = TransactionCsvImportService.new(file_path, options).call

      # Handle results based on what happened
      handle_import_results(options[:force_proceed])

    rescue StandardError => e
      flash[:error] = "Import failed: #{e.message}"
      redirect_to root_path
    ensure
      # Clean up session if we're done (success or force_proceed)
      cleanup_session_file if should_cleanup?
    end
  end

  def categories
    # Parse date range from params (default to current month)
    @date_range = DateRangeService.parse(params[:date_range])
    @transaction_type = params[:transaction_type] || "expense"
    @min_amount = params[:min_amount]&.to_f || 0
    # Get category breakdown using your existing model methods
    @categories_summary = if @transaction_type == "expense"
      Transaction.spending_by_category(@date_range[:start], @date_range[:end])
    elsif @transaction_type == "income"
      Transaction.income.in_date_range(@date_range[:start], @date_range[:end])
                .group(:category).sum(:amount)
    else
      # All transactions
      Transaction.in_date_range(@date_range[:start], @date_range[:end])
                .group(:category).sum(:amount)
    end
    # Filter by minimum amount
    @categories_summary = @categories_summary.select { |_, amount| amount.abs >= @min_amount }

    # Calculate totals and percentages
    @total_amount = @categories_summary.values.sum.abs
    @categories_with_percentages = @categories_summary.map do |category, amount|
      percentage = @total_amount > 0 ? (amount.abs / @total_amount * 100).round(1) : 0
      [ category, { amount: amount.abs.to_f, percentage: percentage.to_f } ]
    end.to_h.sort_by { |_, data| -data[:amount] }.to_h

    # Get transaction count per category
    @transaction_counts = Transaction.in_date_range(@date_range[:start], @date_range[:end])
                                   .where(transaction_type: @transaction_type == "all" ? [ "income", "expense" ] : @transaction_type)
                                   .group(:category).count
  end

  def category_details
    # AJAX endpoint for detailed category view (we'll implement this later)
    render json: { message: "Coming soon!" }
  end

  private

  def validate_file_upload
    @file_valid = true

    unless params[:csv_file].present?
      flash[:error] = "Please select a CSV file"
      redirect_to root_path
      @file_valid = false
      return
    end

    # Check file extension
    filename = params[:csv_file].original_filename
    unless filename.downcase.end_with?('.csv')
      flash[:error] = "Please upload a CSV file (.csv extension required)"
      redirect_to root_path
      @file_valid = false
      return
    end

    # Check file size (optional - adjust limit as needed)
    if params[:csv_file].size > 10.megabytes
      flash[:error] = "File too large. Please upload a CSV file smaller than 10MB"
      redirect_to root_path
      @file_valid = false
    end
  end

  def handle_import_results(force_proceed)
    if !@results[:can_proceed]
      # Fatal issues - cannot proceed under any circumstances
      error_message = "Cannot import CSV file"
      error_message += ": #{@results[:issue_summary].join(', ')}" if @results[:issue_summary].any?
      error_message += ". Please check your CSV file and try again."

      flash[:error] = error_message
      redirect_to root_path

    elsif @results[:issues_detected] && !force_proceed
      # Issues found but user can choose to proceed anyway
      # Render scan results page with proceed option
      render :scan_results

    elsif @results[:issues_detected] && force_proceed
      # Issues found but user chose to proceed - import completed with issues
      message = build_completion_message_with_issues
      flash[:warning] = message
      redirect_to root_path

    else
      # No issues - clean import completed
      flash[:success] = "Import successful! #{@results[:imported]} transactions imported."
      redirect_to root_path
    end
  end

  def get_file_path
    if params[:csv_file].present?
      # First request - validate and store file
      validate_file_upload
      return nil unless @file_valid # Error already set

      # Store file path in session for potential second request
      temp_file = Tempfile.new([ "csv_import", ".csv" ])
      temp_file.binmode
      temp_file.write(params[:csv_file].read)
      temp_file.close
      session[:csv_file_path] = temp_file.path
      session[:csv_file_name] = params[:csv_file].original_filename

      session[:csv_file_path]

    elsif session[:csv_file_path].present?
      # Second request (force proceed) - use stored path
      unless File.exist?(session[:csv_file_path])
        flash[:error] = "File session expired. Please upload your CSV again."
        redirect_to root_path
        return nil
      end

      session[:csv_file_path]

    else
      # No file in request or session
      flash[:error] = "Please select a CSV file to import"
      redirect_to root_path
      nil
    end
  end

  def build_completion_message_with_issues
    message = "Import completed: #{@results[:imported]} transactions imported"
    message += ", #{@results[:skipped]} skipped" if @results[:skipped] > 0

    if @results[:issue_summary].any?
      message += ". Issues: #{@results[:issue_summary].join(', ')}"
    end

    message
  end

  def should_cleanup?
    # Clean up if we're redirecting (success/error) or if force_proceed was used
    !performed? || params[:force_proceed] == "true"
  end

  def cleanup_session_file
    if session[:csv_file_path] && File.exist?(session[:csv_file_path])
      File.delete(session[:csv_file_path]) # Clean up our persistent temp file
    end
    session.delete(:csv_file_path)
    session.delete(:csv_file_name)
  end
end
