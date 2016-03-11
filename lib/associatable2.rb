require_relative 'associatable'

module Associatable
  def has_one_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      through_table = through_options.model_class.table_name
      source_table = source_options.model_class.table_name

      res = DBConnection.execute2(<<-SQL)
        SELECT
          #{source_table}.*
        FROM
          #{through_table}
        JOIN
          #{source_table} ON #{through_table}.#{source_options.foreign_key} = #{source_table}.id
        WHERE
          #{through_table}.id = #{self.send(through_options.foreign_key)}
        SQL

        source_options.model_class.parse_all(res.drop(1)).first
    end

  end
end
