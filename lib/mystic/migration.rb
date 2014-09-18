#!/usr/bin/env ruby

module Mystic
  class Migration
		Error = Class.new StandardError
		IrreversibleError = Class.new StandardError

		def initialize
			@irreversible = false
			@sql = ""
		end
		
		def migrate
			exec_migration :up
		end
		
		def rollback
			exec_migration :down
		end
    
    def to_sql direction
      @sql = ""
			_direction = direction.to_sym
			
			raise ArgumentError, "Direction must be either :up or :down." unless [:up, :down].include? _direction
			raise IrreversibleError, "Impossible to roll back an irreversible migration." if _direction == :down && irreversible?
			
      execute "BEGIN"
			method(_direction).call
      execute "COMMIT"
      
      res = @sql.dup
      @sql = ""
      res
    end
		
		def exec_migration direction
      sql = to_sql direction
			Mystic.postgres.execute sql
		end
		
		
		#
		# DSL
		#
		
		# All migration SQL goes through here
    def execute obj
			@sql << obj.to_s.terminate
    end
		
		def irreversible!
			@irreversible = true
		end
		
		def irreversible?
			@irreversible
		end

    def create_table name
      raise ArgumentError, "No block provided, a block is required to create a table." unless block_given?
      table = Mystic::SQL::Table.create :name => name
      yield table
      execute table
    end
    
    def alter_table name
			raise ArgumentError, "No block provided, a block is required to alter a table." unless block_given?
      table = Mystic::SQL::Table.alter :name => name
      yield table
      execute table
    end
    
    # MIXED_ARGS
    def drop_table name, *opts
      _opts.unify_args
			irreversible!
      sql = []
      sql << "DROP TABLE"
      sql << name.to_s
      sql << "CASCADE" if (opts[:cascade] || opts["cascade"]) == true
      sql << "RESTRICT" if (opts[:restrict] || opts["restrict"]) == true
      execute sql*' '
    end
		
		def drop_index idx_name
      execute "DROP INDEX #{idx_name.to_s}"
		end
    
    def create_ext extname
      execute "CREATE EXTENSION \"#{extname.to_s}\""
    end
    
    def drop_ext extname
      execute "DROP EXTENSION \"#{extname.to_s}\""
    end
    
    def create_view name, sql
      execute "CREATE VIEW #{name.to_s} AS #{sql}"
    end
    
    def drop_view name
      execute "DROP VIEW #{name.to_s}"
    end
  end
end