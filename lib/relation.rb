class Relation
  attr_accessor :select_str, :from_str, :where_str

  def initialize(calling_class, options = {})
    @calling_class = calling_class.constantize
    @select_str = options[:select] || "*"
    @from_str = @calling_class.table_name

    if options[:where]
      @where_str = options[:where].map{|key, val|"#{key} = '#{val}'"}.join(" AND ")
    else
      @where_str = "1"
    end

    @loaded = false
  end


  def where(params)
    @where_str = params.map{|key, val|"#{key} = '#{val}'"}.join(" AND ")
  end

  def select(str)
    @select_str = str
  end

  def load
    @loaded = true

    DBConnection.execute2(<<-SQL)
      SELECT
        #{self.select_str}
      FROM
        #{self.from_str}
      WHERE
        #{self.where_str}
    SQL
  end

  def to_a
    res = self.load

    res.drop(1).inject([]){ |result, r| result << @calling_class.new(r) }
  end

  def count
  end

  def inspect
  end
end
