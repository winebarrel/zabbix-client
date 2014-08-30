class Zabbix::Client::Error < StandardError
  def initialize(error)
    super(error.inspect)
    @error = error
  end

  def error
    @error
  end
end
