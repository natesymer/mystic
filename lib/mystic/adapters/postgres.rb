#!/usr/bin/env ruby

require "mystic/adapter"
require "pg"

# http://en.wikibooks.org/wiki/Converting_MySQL_to_PostgreSQL#Data_Types
POSTGRES_TYPES = {
  :float => "REAL",
  :double => "DOUBLE PRECISION",
  
  :serial => "SERIAL",
  :json => "JSON",
  :xml => "XML",
  :uuid => "UUID"
}

module Mystic
  class Table
    def array(name,  opts={})
      column(:array, name, opts)
    end
  end
end

class PostgresAdapter < Adapter
  def connect(opts)
    create_pool do
      PG.connect(opts)
    end
  end
  
  def disconnect
    @pool.with do |instance|
      instance.close
    end
  end
  
  def exec(sql)
    return nil if @pool.nil?
    puts sql
    res = nil
    @pool.with do |instance|
      res = instance.exec(sql)
    end
    return res
  end
  
  def sanitize(string)
    res = nil
    @pool.with do |instance|
      res = instance.escape_string(string)
    end
    return res
  end

  def sql_kind(kind)
    res = super(kind)
    res ||= POSTGRES_TYPES[kind.to_sym]
    res
  end
  
  def constraint_sql(name, conditions)
    "CONSTRAINT #{name} CHECK(#{conditions})"
  end
  
  def drop_index_sql(*args)
    "DROP INDEX #{args.first}"
  end
end