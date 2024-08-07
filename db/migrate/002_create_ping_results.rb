Sequel.migration do
  change do
    create_table :ping_results do
      primary_key :id
      foreign_key :ip_id, :ips, on_delete: :cascade
      Boolean :success
      Float :rtt
      DateTime :timestamp, default: Sequel::CURRENT_TIMESTAMP
    end
  end
end
