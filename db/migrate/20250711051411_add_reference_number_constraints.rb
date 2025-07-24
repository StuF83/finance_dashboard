class AddReferenceNumberConstraints < ActiveRecord::Migration[8.0]
  def change
    change_column_null :transactions, :reference_number, false
    add_index :transactions, :reference_number, unique: true, name: 'index_transactions_on_reference_number_unique'
  end
end
