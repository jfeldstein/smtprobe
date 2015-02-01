puts "Loading...\n\n"

first_name = nil
last_name  = nil
middle_name = nil
host = nil

ARGV.each_with_index do |k, i|
    v = ARGV[i+1]
    case k
    when '-f'
        first_name  = v
    when '-l'
        last_name   = v
    when '-m'
        middle_name = v
    when '-h'
        host        = v
    end
end

unless first_name && last_name && host
    puts 'ruby name_co_to_email.rb -f <first_name> -l <last_name> -h <host/domain.com>'
    puts "( -f, -l and -h are all required)"
    exit
end



require 'CSV'
require 'email_verifier'

components = {
    'fi' => (first_name[0]  if first_name),
    'fn' => (first_name     if first_name),
    'li' => (last_name[0]   if last_name),
    'ln' => (last_name      if last_name),
    'lis'=> (last_name[0..1] if last_name),
    'mi' => (middle_name[0] if middle_name),
    'mn' => (middle_name    if middle_name)
}

guess_templates = CSV.read('./guess_templates.csv').map{|row| row.first}

guesses = []
emails  = []

guess_templates.each do |t|
    reqs = t.scan(/\{([a-z]+)\}/i).to_a.map{|r| r.first }

    next if reqs.any? {|r| components[r].nil? }

    guess = t.dup
    reqs.each {|r| guess.gsub! "\{#{r}\}", components[r] }
    guesses << guess
end

puts "Checking Guesses: \n\n"

guesses.each do |user|
    begin
        email = "#{user.chomp}@#{host.chomp}"
        EmailVerifier.config do |config| config.verifier_email = email end
        result = EmailVerifier.check email
        puts "#{email} is valid!"   if result
        emails << email             if result
    rescue StandardError => e
        puts e.inspect
    end
end

puts "\nFound #{emails.length} possible!", emails
