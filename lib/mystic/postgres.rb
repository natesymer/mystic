#!/usr/bin/env ruby

require "date" # used by c extension required below
require_relative "../ext/mystic/postgres_ext.bundle"

# Actual-factual replacement for the PG gem.
# Supports connecting, disconnecting, encodings, querying, and escaping
# supports ruby 2.0.0 and newer

# Mystic::Postgres#execute sql
# Executes sql
# Returns a Ruby array of hashes. All hashes contain native ruby numerics/dates/datetimes/etc.

module Mystic
  class Postgres
    REPR_COL = "mystic_repr_col0.2.0".freeze # The column used by Mystic::Model to return JSON or XML
  	CONNECT_FIELDS = [
  		:host,
  		:hostaddr,
  		:port,
  		:dbname,
  		:user,
  		:password,
  		:connect_timeout,
      :client_encoding,
  		:options,
  		:sslmode
  	].freeze

    attr_reader :options
    attr_accessor :single_row_mode

    class << self
      alias_method :connect, :new
    end
    
    # Called by C extension
    def connstr hash={}
      @cs_cache ||= {}
      unless @cs_cache.member? hash
        @cs_cache[hash] = hash
                            .map { |k,v| [k.to_s.downcase, v.to_s] }
                            .select { |k,v| CONNECT_FIELDS.include? k.to_sym }
                            .map { |k,v| "#{k}='#{v.gsub(/[\\']/, &'\\'.method(:+))}'" }
                            .join(' ')
      end
      @cs_cache[hash]
    end
  end
end