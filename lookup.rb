module Lookup

  def check_email(email)
      begin
          EmailVerifier.config do |config| config.verifier_email = email end
          r = EmailVerifier.check email
      rescue StandardError => e
          puts e.inspect
      end
  end

  def guess_templates
    @templates ||= CSV.read('./guess_templates.csv').map{|row| row.first}
  end

  def build_logger(logger=nil)
    -> (*args) { logger.nil? ? puts(args) : logger << args }
  end

  def lookup_by_name(opts)
    output = opts[:out] || []

    guesses = []
    emails  = []

    first_name  = opts[:f]
    last_name   = opts[:l]
    middle_name = opts[:m]
    host        = opts[:d]

    if first_name && last_name && host
      output << "LOOKING FOR:"
      output << opts.inspect
    else
      output << 'ruby name_co_to_email.rb -f <first_name> -l <last_name> -d <host/domain.com>'
      output << "( -f, -l and -d are all required)"
      output << ' '
      output << 'As a server:'
      output << '/discover?f=...&l=...&d=...'
      return output
    end

    components = {
        'fi' => (first_name[0]  if first_name),
        'fn' => (first_name     if first_name),
        'li' => (last_name[0]   if last_name),
        'ln' => (last_name      if last_name),
        'lis'=> (last_name[0..1] if last_name),
        'mi' => (middle_name[0] if middle_name),
        'mn' => (middle_name    if middle_name)
    }

    guess_templates.each do |t|
        reqs = t.scan(/\{([a-z]+)\}/i).to_a.map{|r| r.first }

        next if reqs.any? {|r| components[r].nil? }

        guess = t.dup
        reqs.each {|r| guess.gsub! "\{#{r}\}", components[r] }
        guesses << guess
    end

    # Test an email we know should be garbage,
    # to see if the target server will correctly
    # ID it, vs false positive it.
    output << "Sanity Checking..."
    fake  = 'ljkadslhjka@' + host
    sane  = ! check_email(fake)

    if not sane
        output << "FAIL. Server gives false positives."
        return output
    end


    output << "Checking Guesses: \n\n"

    guesses.each do |user|
        email = "#{user.chomp}@#{host.chomp}"
        result = check_email email
        output <<  "#{email} is valid!"   if result
        emails << email                   if result
    end

    output << "\nFound #{emails.length} possible!"
    emails.each {|e| output << e}
  end
end
