require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns unless @columns.nil?

    table_info = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        "#{table_name}"
      SQL

    @columns = table_info[0].map { |col| col.to_sym }
    @columns
  end

  def self.finalize!
    self.columns.each do |column|
      define_method(column) do
        self.attributes[column]
      end
      define_method("#{column}=") do |n|
        self.attributes[column] = n
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    scname = self.name.downcase.pluralize
    @table_name ||= scname
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        "#{table_name}"
      SQL

    ret = []
    results.each do |result|
      ret << eval(self.name + ".new(" + result.to_s + ")")
    end
    ret
  end

  def self.parse_all(results)
    results ||= self.all?
    ret = []
    results.each do |sub_hash|
      ret << eval(self.name + ".new(" + sub_hash.to_s + ")")
    end
    ret
  end

  def self.find(id)
    obj = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        "#{table_name}"
      WHERE
        id = ?
      SQL

    return nil if obj[0].nil?

    obj = obj[0]

    eval(self.name + ".new(" + obj.to_s + ")")

  end

  def initialize(params = {})
    params.each do |key, value|
      sym_key = key.to_sym
      raise "unknown attribute '#{sym_key}'" unless self.class.columns.include?(sym_key)
      self.send("#{sym_key}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    @attributes.values
  end

  def insert
    # BROKEN
    # col_names =  self.class.columns.join(",")
    # question_marks = "(" + "? " * col_names.length + ")"
    #
    #
    # DBConnection.execute(<<-SQL, question_marks)
    #   INSERT INTO
    #     "#{col_names}"
    #   VALUES
    #     question_marks
    # SQL
  end

  def update
    # ...
  end

  def save
    # ...
  end
end
