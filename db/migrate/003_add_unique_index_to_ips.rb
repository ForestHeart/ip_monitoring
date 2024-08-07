Sequel.migration do
  change do
    alter_table(:ips) do
      add_unique_constraint :address
    end
  end
end
