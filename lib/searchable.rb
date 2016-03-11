require_relative 'db_connection'
require_relative 'sql_object'
require_relative 'relation'


module Searchable
  def where(params)

    # Relation.new(self.to_s, where: params)
    Relation.new(self.to_s, where: params).to_a


    where_str = params.keys.map{ |key| "#{key} = ?" }.join(" AND ")

    values = params.values

    res = DBConnection.execute2(<<-SQL, *values)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_str}
    SQL

    res.drop(1).inject([]){ |result, r| result << self.new(r) }
  end

end

class SQLObject
  extend Searchable
end
