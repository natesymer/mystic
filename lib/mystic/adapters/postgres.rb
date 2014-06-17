#!/usr/bin/env ruby

require "mystic"
require "mystic/adapter"
require "pg"
require "mystic/model"
require "mystic/sql"

# Mystic adapter for Postgres, includes PostGIS

module Mystic
	class PostgresAdapter < Mystic::Adapter
		INDEX_TYPES = [:btree, :hash, :gist, :spgist, :gin]
		
		connect { |opts| PG.connect opts }
		disconnect { |pg| pg.close }
		validate { |pg| pg.status == CONNECTION_OK }
		sanitize { |pg, str| pg.escape_string string }
		
		execute do |inst, sql|
			res = inst.exec sql
			ret = res[0][Mystic::Model::JSON_COL] if res.ntuples == 1 && res.nfields == 1
			ret ||= res.ntuples.times.map { |i| res[i] } unless res.nil?
			ret ||= []
			ret
		end
		
		drop_index do |index| 
			"DROP INDEX #{index.index_name}"
		end
		
		create_extension do |ext| 
			"CREATE EXTENSION \"#{ext.name}\""
		end
		
		drop_extension do |ext|
			"DROP EXTENSION \"#{ext.name}\"" 
		end
		
		index do |index|
			storage_params = index.opts.subhash :fillfactor,:buffering,:fastupdate
			
			sql = []
			sql << "CREATE"
			sql << "UNIQUE" if index.unique
			sql << "INDEX"
			sql << "CONCURENTLY" if index.concurrently
		  sql << index.name unless index.name.nil?
		  sql << "ON #{index.table_name}"
			sql << "USING #{index.type}" if INDEX_TYPES.include? index.type
			sql << "(#{index.columns.map(&:to_s).join ',' })"
			sql << "WITH (#{storage_params.sqlize})" unless storage_params.empty?
			sql << "TABLESPACE #{index.tablespace}" unless index.tablespace.nil?
			sql << "WHERE #{index.where}" unless index.nil?
			sql*' '
		end
	end
end