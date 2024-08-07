require 'sequel'

class PingResult < Sequel::Model
  many_to_one :ip
end
