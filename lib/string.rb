# coding: UTF-8
class String
  def smess_to_underscore
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end


  def split_at(index)
      [ self[0, index], self[index..-1] || "" ]
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
  end
  def msisdn!(country_code = 1, force_country_code = false)
    self.gsub!(/\D/,"")

    if begins_with_msisdn_international_prefix
      self.replace(self[2..-1])
    elsif begins_with_msisdn_national_prefix
      self.replace(self[1..-1])
      ensure_msisdn_countrycode_prefix(country_code)
    elsif force_country_code
      ensure_msisdn_countrycode_prefix(country_code)
    end

    validate_msisdn_length_range
    self
  end

  private

  def begins_with_msisdn_international_prefix
    length > 0 && self[0..1] == "00"
  end

  # correct most places in the world but notably not in north america (1... countries)
  def begins_with_msisdn_national_prefix
    length > 0 && self[0] == "0"
  end

  # Add country code unless the start of the number is the correct country code
  def ensure_msisdn_countrycode_prefix(country_code)
    unless self[0..country_code.to_s.length-1] == country_code.to_s
      self.prepend(country_code.to_s)
    end
  end

  def validate_msisdn_length_range
    unless (10..15) === self.length
      self.replace("")
    end
  end


end
