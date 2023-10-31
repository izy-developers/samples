class BaseQuery
  SEPARATOR = Arel::Nodes.build_quoted(' ')

  def self.call(collection, params = {})
    new(collection, params).call
  end

  def initialize(collection = record_class.all, params = {})
    @collection = collection
    @params = params
  end

  attr_reader :collection, :params

  private

  def table
    record_class.arel_table
  end
end
