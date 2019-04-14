require_relative 'verifier_helper'
require 'flamegraph'

Flamegraph.generate('./final.html') do
  if ARGV.empty? # If no command line args
    puts "Usage: ruby verifier.rb <name_of_file>\n\tname_of_file = name of file to verify"
    exit 1
  else
    file = ARGV[0]
    start = D4.new
    start.read(file)
  end
end
