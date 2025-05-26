class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.date :transaction_date, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :description, null: false
      t.string :category, default: 'Uncategorized'
      t.string :transaction_type # 'income' or 'expense'
      t.string :account_name
      t.string :reference_number
      t.text :notes

      t.timestamps
    end

    add_index :transactions, :transaction_date
    add_index :transactions, :category
    add_index :transactions, :transaction_type
    add_index :transactions, [:transaction_date, :transaction_type]
  end
end
