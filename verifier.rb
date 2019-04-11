require 'flamegraph'

Flamegraph.generate('./initial.html') do
  # Globals
  $prev_hash = "0" # Keeps track of previous hash
  $prev_time = "0.0" # Keeps track of previous timestamp
  $line_num = 0 # Keeps track of line number
  $addresses = Hash.new() # Hash of {addresses => billcoins}

  # Checks if block number is valid
  def check_num (block_num)
      if (block_num.to_i != $line_num)
          abort("Line #{$line_num}: Invalid block number #{block_num}, should be #{$line_num}\nBLOCKCHAIN INVALID")
      end
  end

  # Checks if stored previous hash matches the previous hash in the block
  def check_prev_hash (prev_hash, hash)
      if $prev_hash != prev_hash
          abort("Line #{$line_num}: Previous hash was #{prev_hash}, should be #{$prev_hash}\nBLOCKCHAIN INVALID")
      else
          $prev_hash = hash.gsub("\n","")
      end
  end

  # Checks that timestamp of current block is not greater than or equal to the block timestamp
  def check_time (time)
      prev_time_sec = $prev_time.split(".")[0].to_i
      prev_time_nano = $prev_time.split(".")[1].to_i
      curr_time_sec = time.split(".")[0].to_i
      curr_time_nano = time.split(".")[1].to_i
      if (prev_time_sec >= curr_time_sec && prev_time_nano >= curr_time_nano)
          abort("Line #{$line_num}: Previous timestamp #{$prev_time} >= new timestamp #{time}\nBLOCKCHAIN INVALID")
      end
      $prev_time = time
  end

  # Checks that addresses are valid
  def check_addresses (addresses)
      if (addresses[0].length > 6)
          abort("Line #{$line_num}: Invalid address #{addresses[0]}\nBLOCKCHAIN INVALID")
      elsif (addresses[1].length > 6)
          abort("Line #{$line_num}: Invalid address #{addresses[1]}\nBLOCKCHAIN INVALID")
      end
  end

  def check_format (transactions)
      if (!transactions.include?(">"))
          abort ("Line #{$line_num}: Could not parse transactions list '#{transactions}'\nBLOCKCHAIN INVALID")
      end
      # Other possible checks?
  end

  # Obtains the billcoins and addresses involved in each transaction, then executes each transaction
  # Returns an array of the addresses involved in transactions in the block
  def process_transactions (transactions)
      block_addresses = Array.new()
      transactions.split(":").each do |transaction|
          billcoins = transaction[/\(.*?\)/].gsub(/[()]/, "").to_i  # Regex to obtain billcoins traded in parentheses
          addresses = transaction.gsub(/\(.*?\)/, "").split(">") # Obtain pair of addresses involved in transaction
          check_addresses(addresses)
          block_addresses.push(addresses[0], addresses[1])
          if (addresses[0] != "SYSTEM")
              withdraw(billcoins, addresses[0])
          end
          add(billcoins, addresses[1])
      end
      block_addresses
  end

  # Subtracts billcoins from the sender
  def withdraw (billcoins, sender)
      if($addresses[sender].nil?)
          $addresses[sender] = -billcoins
      else
          $addresses[sender] -= billcoins
      end
  end

  # Adds billcoins to the receiver
  def add (billcoins, receiver)
      if($addresses[receiver].nil?)
          $addresses[receiver] = billcoins
      else
          $addresses[receiver] += billcoins
      end
  end

  # Calculates the hash for the current block
  def calc_hash (line)
      string_to_hash = "#{line[0]}|#{line[1]}|#{line[2]}|#{line[3]}".unpack('U*')
      sum = 0;
      string_to_hash.each do |x|
          sum += ((x**3000) + (x**x) - (3**x)) * (7**x)
      end
      result = (sum % 65536).to_s(16)
      result
  end

  def check_hash (found_hash, line)
      if (found_hash != line[4].gsub("\n",""))
          abort("Line #{$line_num}: String '#{line[0]}|#{line[1]}|#{line[2]}|#{line[3]}' hash set to #{line[4]}, should be #{found_hash}\nBLOCKCHAIN INVALID")
      end
  end

  # Reads through the file and extracts the information from each line
  # Checks for any invalidity, then prints out the addresses and billcoins
  def read (file)
      File.foreach(file).with_index { |line, line_num|
          line = line.split("|") # Split the line using the pipes
          $line_num  = line_num
          block_num = line[0] # Block number
          prev_hash = line[1] # Hash of previous block
          transactions = line[2] # Sequence of transactions
          timestamp = line[3] # Timestamp
          hash = line[4] # Hash of the first four elements
          found_hash = calc_hash(line)

          check_format(transactions)
          check_num(block_num)
          check_hash(found_hash, line)
          check_prev_hash(prev_hash, hash)
          check_time(timestamp)

          addresses = process_transactions(transactions).uniq # Get all unique addresses involved in transactions in the block
          for address in addresses do
              if address != "SYSTEM" && $addresses[address] < 0 # If an address has negative billcoins
                  abort("Line #{$line_num}: Invalid block, address #{address} has #{$addresses[address]} billcoins!\nBLOCKCHAIN INVALID")
              end
          end
      }
      $addresses = $addresses.delete_if{|_,billcoins| billcoins == 0} # Remove all addresses with 0 billcoins
      $addresses.sort.to_h.each do |address, billcoins|
          puts "#{address}: #{billcoins} billcoins" # Print out addresses and billcoins
      end
  end

  if(ARGV.empty?) # If no command line args
      puts("Usage: ruby verifier.rb <name_of_file>\n\tname_of_file = name of file to verify")
      exit 1
  else
      file = ARGV[0]
      read(file)
  end
end
