require 'email_verifier'

def usage
    puts 'ruby smtp-user-vrfy.rb -u <filename of users> -h <filename of hosts> -o <output file>'
    puts 'users file should have a single username per line'
    puts 'hosts file should have a single host per line'
    puts 'output file is optional'
    exit
end

usage() if ARGV.count < 4 and ARGV[0] != '-u' and ARGV[2] != '-h'

users = File.expand_path(ARGV[1])
hosts = File.expand_path(ARGV[3])

log = nil

if ARGV.count > 5 and ARGV[4] == '-o'
    log = File.open(File.expand_path(ARGV[5]), 'w')
    puts "logging to #{log}"
end

File.open(hosts, 'r') do |hf|
    hf.each_line do |host|
        msg = "Checking users on #{host.chomp}"
        puts msg
        log.puts "#{msg}\n" unless log.nil?

        File.open(users, 'r') do |uf|
            uf.each_line do |user|
                begin
                    email = "#{user.chomp}@#{host.chomp}"
                    EmailVerifier.config do |config| config.verifier_email = email end
                    result = EmailVerifier.check email
                    msg = "#{email}? #{result.inspect}"
                    puts msg
                    log.puts "\t #{msg}\n" unless log.nil?
                rescue StandardError => e
                    puts e.inspect
                    log.puts "\t #{e.inspect}\n" unless log.nil?
                end
            end
        end
    end
end

log.close unless log.nil?
