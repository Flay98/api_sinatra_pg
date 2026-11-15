Sequel.migration do
  change do
    create_table(:jobs) do
      primary_key :id
      String :name, text: true, null: false
      String :place, text: true, null: false
      foreign_key :company_id, :companies, null: false, on_delete: :restrict
      DateTime :created_at
      DateTime :updated_at
      index :company_id
      constraint(:jobs_name_present) { char_length(trim(name)) > 0 }
      constraint(:jobs_place_present) { char_length(trim(place)) > 0 }
    end
  end
end
