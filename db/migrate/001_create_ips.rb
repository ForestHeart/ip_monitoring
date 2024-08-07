Sequel.migration do
  change do
    create_table :ips do
      primary_key :id
      String :address, null: false, unique: true
      Boolean :enabled, default: false
      DateTime :created_at
      DateTime :updated_at
    end
  end
end
