Sequel.migration do
  change do
    create_table(:companies) do
      primary_key :id
      String :name, text: true, null: false
      String :location, text: true, null: false
      DateTime :created_at
      DateTime :updated_at
      constraint(:companies_name_present) { char_length(trim(name)) > 0 }
      constraint(:companies_location_present) { char_length(trim(location)) > 0 }
    end
  end
end
