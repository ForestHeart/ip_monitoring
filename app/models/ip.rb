require 'sequel'
require_relative './ping_result'

class IP < Sequel::Model
  one_to_many :ping_results

  def validate
    super
    errors.add(:address, 'is not a valid IP address') unless IPAddress.valid?(address)
    errors.add(:address, 'is already taken') if IP.where(address: address).exclude(id: id).count > 0
  end
end
