Sequel.migration do
  change do
    create_table(:geeks) do
      primary_key :id
      String :name, text: true, null: false
      String :stack, text: true, null: false
      TrueClass :resume, default: false, null: false
      DateTime :created_at
      DateTime :updated_at
      constraint(:geeks_name_present) { char_length(trim(name)) > 0 }
      constraint(:geeks_stack_present) { char_length(trim(stack)) > 0 }
    end
  end
end
