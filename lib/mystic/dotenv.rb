#!/usr/bin/env ruby

require_relative "./root"

::DOTENV = Hash[Mystic.root.join(".env").each_line.map { |l| l.strip.split "=", 2 }] rescue {}
::DOTENV.each { |k,v| ::ENV[k] = v }