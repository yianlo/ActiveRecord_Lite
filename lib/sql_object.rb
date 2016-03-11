require_relative 'db_connection'
require 'active_support/inflector'
require_relative 'searchable'

class SQLObject

  def self.columns
    @column ||= DBConnection.execute2(<<-SQL).first.map(&:to_sym)
      SELECT
        *
      FROM
        #{table_name}
    SQL
  end

  def self.finalize!
    columns.each do |column|
      define_method("#{column}") do
        attributes[column]
      end

      define_method("#{column}=") do |val|
        attributes[column] = val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.to_underscore!.pluralize
  end

  def self.all
    res = DBConnection.execute2(<<-SQL).drop(1)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
    SQL

    parse_all(res)
  end

  def self.parse_all(results)
    results.map{ |result| self.new(result) }
  end

  def self.find(id)
    res = DBConnection.execute2(<<-SQL, id)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL

    res[1].nil? ? nil : self.new(res[1])
  end

  def initialize(params = {})
    self.class.finalize!
    # send(:attributes)

    params.each do |key, val|
      key = key.to_sym

      raise "unknown attribute '#{key}'" unless self.class.columns.include?(key)
      send("#{key}=", val)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    @attributes.values
  end

  def insert
    a = attribute_values

    columns = self.class.columns.drop(1)
    col_names = columns.join(", ")

    ques = ["?"] * columns.size
    ques_str = ques.join(", ")

    table_name = self.class.table_name

    DBConnection.execute2(<<-SQL, *a)
      INSERT INTO
        #{table_name}(#{col_names})
      VALUES
        (#{ques_str})
    SQL

    self.id= DBConnection.execute2(<<-SQL).last["id"]
      SELECT
        id
      FROM
        #{table_name}
      WHERE
        #{columns.first} = '#{a.first}'
    SQL
  end

  def update
    a = attribute_values.drop(1) + attribute_values.take(1)
    col_names = self.class.columns.drop(1).map{ |col| "#{col} = ?" }.join(", ")

    DBConnection.execute2(<<-SQL, *a)
      UPDATE
        #{self.class.table_name}
      SET
        #{col_names}
      WHERE
        id = ?
    SQL
  end

  def save
    self.id.nil? ? insert : update
  end
  #
  # def validates(column, options = {})
  #   options[uniqueness] =
  # end

  def includes(other_table)
    res = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        self.table_name
      SQL

    other_table_content = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{other_table_name}
      WHERE
        #{self.downcase.to_s}.id IS NOT NULL
    SQL

    other_table_array = parse_all(other_table_content.drop(1))

    define_method(other_table) do

    end

    parse_all(res.drop(1))
  end
end


class String

  def to_underscore!
    gsub!(/(.)([A-Z])/,'\1_\2')
    downcase!
  end
end
