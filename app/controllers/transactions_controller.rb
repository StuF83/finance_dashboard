class TransactionsController < ApplicationController
  def index
    @transactions = if params[:date_range].present?
                      date_range = DateRangeService.parse(params[:date_range])
                      Transaction.in_date_range(date_range[:start], date_range[:end]).recent
    else
      Transaction.recent
    end
  end

  def bulk_destroy
    transaction_ids = params[:transaction_ids]

    if transaction_ids.blank?
      redirect_to transactions_path, alert: "No transactions selected for deletion."
      return
    end

    begin
      # Find and validate all transactions exist and belong to current user (if applicable)
      transactions_to_delete = Transaction.where(id: transaction_ids)

      if transactions_to_delete.count != transaction_ids.count
        redirect_to transactions_path, alert: "Some transactions could not be found."
        return
      end

      # Perform the bulk deletion
      deleted_count = transactions_to_delete.destroy_all.count

      if deleted_count > 0
        redirect_to transactions_path,
                   notice: "Successfully deleted #{deleted_count} transaction#{'s' if deleted_count != 1}."
      else
        redirect_to transactions_path, alert: "No transactions were deleted."
      end

      rescue ActiveRecord::RecordNotDestroyed => e
        redirect_to transactions_path,
                   alert: "Failed to delete some transactions: #{e.message}"
      rescue StandardError => e
        Rails.logger.error "Bulk delete error: #{e.message}"
        redirect_to transactions_path,
                   alert: "An error occurred while deleting transactions."
    end
  end
end
