Sequel.migration do
  change do
    create_table(:applies) do
      primary_key :id
      foreign_key :job_id, :jobs, null: false, on_delete: :restrict
      foreign_key :geek_id, :geeks, null: false, on_delete: :restrict
      TrueClass :read, default: false, null: false
      TrueClass :invited, default: false, null: false
      DateTime :created_at
      DateTime :updated_at
      index :job_id
      index :geek_id
    end
  end
end
