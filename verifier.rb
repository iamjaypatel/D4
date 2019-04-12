# frozen_string_literal: true

require 'flamegraph'

# Checks if block number is valid
def check_num(block_num, line_num)
  return if block_num.to_i == line_num

  abort("Line #{line_num}: Invalid block number #{block_num}, should be #{line_num}\nBLOCKCHAIN INVALID")
end

# Checks if stored previous hash matches the previous hash in the block
def check_prev_hash(prev_hash, block_prev_hash, hash, line_num)
  if prev_hash != block_prev_hash
    abort("Line #{line_num}: Previous hash was #{block_prev_hash}, should be #{prev_hash}\nBLOCKCHAIN INVALID")
  end
  hash.delete("\n")
end

# Checks that timestamp of current block is not greater than or equal to the block timestamp
def check_time(time, prev_time, line_num)
  prev_time_sec = prev_time.split('.')[0].to_i
  prev_time_nano = prev_time.split('.')[1].to_i
  curr_time_sec = time.split('.')[0].to_i
  curr_time_nano = time.split('.')[1].to_i
  if prev_time_sec >= curr_time_sec && prev_time_nano >= curr_time_nano
    abort("Line #{line_num}: Previous timestamp #{prev_time} >= new timestamp #{time}\nBLOCKCHAIN INVALID")
  end
  time
end

# Checks that addresses are valid
def check_addresses(addresses, line_num)
  if addresses[0].length > 6 || addresses[0].match?(/[A-Za-z]/) && addresses[0] != 'SYSTEM'
    abort("Line #{line_num}: Invalid address #{addresses[0]}\nBLOCKCHAIN INVALID")
  elsif addresses[1].length > 6 || addresses[1].match?(/[A-Za-z]/)
    abort("Line #{line_num}: Invalid address #{addresses[1]}\nBLOCKCHAIN INVALID")
  end
end

def check_format(transactions, line_num)
  return if transactions.include?('>')

  abort("Line #{line_num}: Could not parse transactions list '#{transactions}'\nBLOCKCHAIN INVALID")
end

# Obtains the billcoins and addresses involved in each transaction, then executes each transaction
# Returns an array of the addresses involved in transactions in the block
def process_transactions(transactions, line_num, addresses)
  block_addresses = []
  transactions.split(':').each do |transaction|
    billcoins = transaction[/(?<=\()\w+(?=\)$)/].to_i # Regex to obtain billcoins traded in parentheses
    address_pair = transaction.gsub(/\(.*?\)/, '').split('>') # Obtain pair of addresses involved in transaction
    check_addresses(address_pair, line_num)
    block_addresses.push(address_pair[0], address_pair[1])
    withdraw(billcoins, address_pair[0], addresses) if address_pair[0] != 'SYSTEM'
    add(billcoins, address_pair[1], addresses)
  end
  block_addresses
end

# Subtracts billcoins from the sender
def withdraw(billcoins, sender, addresses)
  if addresses[sender].nil?
    addresses[sender] = -billcoins
  else
    addresses[sender] -= billcoins
  end
end

# Adds billcoins to the receiver
def add(billcoins, receiver, addresses)
  if addresses[receiver].nil?
    addresses[receiver] = billcoins
  else
    addresses[receiver] += billcoins
  end
end

# Calculates the hash for the current block
# Memoization?
def calc_hash(line, calculations)
  string_to_hash = "#{line[0]}|#{line[1]}|#{line[2]}|#{line[3]}".unpack('U*')
  sum = 0
  string_to_hash.each do |x|
    calculations[x] = ((x**3000) + (x**x) - (3**x)) * (7**x) if calculations[x].nil?
    sum += calculations[x]
  end
  result = (sum % 65_536).to_s(16)
  result
end

def check_hash(found_hash, line, line_num)
  return if found_hash == line[4].delete("\n")

  puts "Line #{line_num}: String '#{line[0]}|#{line[1]}|#{line[2]}|#{line[3]}'
    hash set to #{line[4]}, should be #{found_hash}"
  puts 'BLOCKCHAIN INVALID'
  exit 1
end

# Reads through the file and extracts the information from each line
# Checks for any invalidity, then prints out the addresses and billcoins
def read(file)
  line_num = 0
  prev_hash = '0'
  prev_time = '0.0'
  addresses = {}
  calculations = {}
  File.foreach(file) do |line|
    line = line.split('|') # Split the line using the pipes
    block_num = line[0] # Block number
    block_prev_hash = line[1] # Hash of previous block
    transactions = line[2] # Sequence of transactions
    timestamp = line[3] # Timestamp
    hash = line[4] # Hash of the first four elements
    found_hash = calc_hash(line, calculations)

    check_num(block_num, line_num)
    check_format(transactions, line_num)
    check_hash(found_hash, line, line_num)
    prev_hash = check_prev_hash(prev_hash, block_prev_hash, hash, line_num)
    prev_time = check_time(timestamp, prev_time, line_num)

    uniq_addresses = process_transactions(transactions, line_num, addresses).uniq # Get unique addresses w/ transactions
    uniq_addresses.each do |address|
      if address != 'SYSTEM' && (addresses[address]).negative? # If an address has negative billcoins
        puts "Line #{line_num}: Invalid block, address #{address} has #{addresses[address]} billcoins!"
        puts 'BLOCKCHAIN INVALID'
        exit 1
      end
    end
    line_num += 1
  end
  addresses = addresses.delete_if { |_, billcoins| billcoins.zero? } # Remove all addresses with 0 billcoin
  addresses.sort.each do |data|
    puts "#{data[0]}: #{data[1]} billcoins" # Print out addresses and billcoins
  end
end

Flamegraph.generate('./initial.html') do
  if ARGV.empty? # If no command line args
    puts "Usage: ruby verifier.rb <name_of_file>\n\tname_of_file = name of file to verify"
    exit 1
  else
    file = ARGV[0]
    read(file)
  end
end
