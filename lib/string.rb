class String
  def to_underscore
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end


  def valid_utf8?
    !!unpack("U") rescue false
  end

  def utf8_safe_split(n)
    if length <= n
      [self, nil]
    else
      before = self[0, n]
      after = self[n..-1]
      until after.valid_utf8?
        n = n - 1
        before = self[0, n]
        after = self[n..-1]
      end
      [before, after.empty? ? nil : after]
    end
  end

  # like strlen but with SMS alphabet calculations
  def sms_length
    escaped = Regexp.escape('€|^{}[]~\\')
    pattern = Regexp.new( "["+escaped+"]" )

    self.length + self.scan(pattern).length
  end


  def strip_nongsm_chars(replacement = "")
    ret = self.dup
    ret.strip_nongsm_chars!(replacement)
    ret
  end

  # Cleans a string to comply with the GSM alphabet
  def strip_nongsm_chars!(replacement = "")
    # Should this be a patch to String?

    # keeping them here in canse I need them
    # basic alpha
    # '@','£','$','¥','è','é','ù','ì','ò','Ç',"\n",'Ø','ø',"\r",'Å','å',
    # 'Δ','_','Φ','Γ','Λ','Ω','Π','Ψ','Σ','Θ','Ξ','Æ','æ','ß','É',' ',
    # '!','"','#','¤','%','&','\'','(',')','*','+',',','-','.','/','0',
    # '1','2','3','4','5','6','7','8','9',':',';','<','=','>','?','¡',
    # 'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
    # 'Q','R','S','T','U','V','W','X','Y','Z','Ä','Ö','Ñ','Ü','§','¿',
    # 'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p',
    # 'q','r','s','t','u','v','w','x','y','z','ä','ö','ñ','ü','à'
    #
    # extended alpha
    # '|','^','€','{','}','[',']','~','\\'

    allowed = '@£$¥èéùìòÇ'+"\n"+'Øø'+"\r"+'ÅåΔ_ΦΓΛΩΠΨΣΘΞÆæßÉ'+' '+Regexp.escape('!"#¤%&\'()*+,-.')+'\/'+Regexp.escape('0123456789:;<=>?¡ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÑÜ§¿abcdefghijklmnopqrstuvwxyzäöñüà|^€{}[]~\\')

    map = {
      /á|â|ã/ => "a",
      /ê|ẽ|ë/ => "e",
      /í|î|ï/ => "i",
      /ó|ô|õ/ => "o",
      /ú|ů|û/ => "u",
      /ç/ => "Ç"
    }

    map.each do |key, value|
      self.gsub!(key, value)
    end

    pattern = Regexp.new( "[^"+allowed+"]" )
    self.gsub!(pattern,"")
  end


  # cleans and adds the country prefix on the string given preserveing any existing country code
  # this is not entirely problem-free for US area codes without leading 0.
  # if force_country_code is set it forces the selected country prefix on the string given
  # yes old, yes crappy, yes convoluted... legacy stuff, ok.
  def msisdn(*args)
    ret = self.dup
    ret.msisdn!(*args)
    ret.empty? ? nil : ret
  end
  def msisdn!(country_code = 1, force_country_code = false)
    self.replace("") and return self if /\{[a-z]+:.+\}/.match(self) # custom crap

    # make num all digits
    self.gsub!(/\D/,"")

    if length > 0 && self[0..1] == "00"
      self.replace(self[2..-1])
    elsif length > 0 && self[0] == "0"
      # cut away leading zeros
      self.replace(self[1..-1])
      # Add country code unless the start of the number is the correct country code
      unless self[0..country_code.to_s.length-1] == country_code.to_s
        self.prepend(country_code.to_s)
      end
    elsif force_country_code
      # Add country code unless the start of the number is the correct country code
      unless self[0..country_code.to_s.length-1] == country_code.to_s
        self.prepend(country_code.to_s)
      end
    end

    # number must be in a valid range
    unless (10..15) === self.length
      self.replace("") and return self
    end

    self
  end

end
