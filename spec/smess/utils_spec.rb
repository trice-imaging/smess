# coding: UTF-8
require 'spec_helper'

describe "Smess Utils", iso_id: "7.4" do

  before(:all) do
    @gsm_chars = '@£$¥èéùìòÇ'+"\n"+'Øø'+"\r"+'ÅåΔ_ΦΓΛΩΠΨΣΘΞÆæßÉ !"#¤%&\'()*+,-./0123456789:;<=>?¡ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÑÜ§¿abcdefghijklmnopqrstuvwxyzäöñüà|^€{}[]~\\'
    @folded_to_a = 'áâã'
    @stripped = '“”ÿŸ'
  end

  it "cleans phone numbers" do
    "\r\n +(070-123)\n45 67\n".msisdn(46).should == '46701234567'
    '46701234567'.msisdn(46).should == '46701234567'
    '44701234567'.msisdn(46).should == '44701234567'
    '0049701234567'.msisdn(46).should == '49701234567'
    '(858) 123-4567'.msisdn(46).should == '8581234567'
    '1234'.msisdn(46).should == ''
    'BEA790507'.msisdn(46).should == ''
  end

  it "cleans phone numbers forcing given country code" do
    "\r\n +(070-123)\n45 67\n".msisdn(46, true).should == '46701234567'
    '46701234567'.msisdn(46, true).should == '46701234567'
    '0049701234567'.msisdn(46, true).should == '49701234567'
    '(858) 123-4567'.msisdn(46, true).should == '468581234567'
    '1234'.msisdn(46, true).should == ''
    'BEA790507'.msisdn(46, true).should == ''
  end

  it 'is idempotent when re-cleaning valid msisdn' do
    '46701234567'.msisdn(46).msisdn(46).should == '46701234567'
    '46701234567'.msisdn(46, true).msisdn(46).should == '46701234567'
  end

  it "returns an empty string when cleaning invalid msisdn" do
    'hello'.msisdn.should == ''
  end

  it "turns string empty when cleaning invalid msisdn in place" do
    'hello'.msisdn!.should == ''
  end

  it "can count the length of an sms message in extended String class" do
    string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÑÜ§¿abcdefghijklmnopqrstuvwxyzäöñüà|^€{}[]~\\'
    string.sms_length.should == 81
  end

  describe "#split_sms" do
    it "can take a 160 char sms message" do
      string = 'ääää aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa ääää €aaa'
      arr = Smess.split_sms(string)
      arr.length.should == 1
      arr[0].sms_length.should == 160
    end

    it "can split an sms message into concat parts" do
      # long message that is actually being split
      string = 'ääää aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa ä€ää 28/1. pris 339/mån. Provträna gratis hela vecka 48 på nya Nautilus Regeringsgatan 59. Mer info på nautilusgym.se. Välkommen till oss. Nautilus Hammarby Sjöstad'
      arr = Smess.split_sms(string)
      arr.length.should == 3
      arr[0].sms_length.should == 154
      arr[1].sms_length.should == 154
      arr[2].sms_length.should == 7
    end

    it "can split with any character at the split point" do
      string = 'ääää aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa a€€€ä aaaa aaaa'
      arr = Smess.split_sms(string)
      arr.length.should == 2
      arr[0].sms_length.should == 153
      arr[1].sms_length.should == 15
    end

    it "can split with any character at the split point, a variation" do
      string = 'ääää aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa äbbä aaaa aaaa'
      arr = Smess.split_sms(string)
      arr.length.should == 2
      arr[0].sms_length.should == 154
      arr[1].sms_length.should == 10
    end

    it "can split to the correct length according to the gsm alphabet" do
      # € and a few other characters are 2-byte characters
      string = 'ääää €€€€ €€€€ €€€€ €€€€ aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa äbbä aaaa aaaa'
      arr = Smess.split_sms(string)
      arr.length.should == 2
      arr[0].sms_length.should == 154
      arr[1].sms_length.should == 26
    end

  end

  describe "#separate_sms" do
    it "can take a 160 char sms message" do
      string = 'ääää aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa ääää €aaa'
      arr = Smess.separate_sms(string)
      arr.length.should == 1
      arr[0].sms_length.should == 160
    end

    it "separates a string on whitespace to allow sending multiple non-concat messages" do
      string = "aaaaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa last\tnext bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb last next cccc cccc"
      arr = Smess.separate_sms(string)
      arr.length.should == 3
      arr[0].sms_length.should == 156
      arr[1].sms_length.should == 159
      arr[2].sms_length.should == 14
    end

    it "calculates the separation point respecting the GSM alphabet" do
      # € and a few other characters are 2-byte characters
      string = 'aaaaaa €€€€ €€€€ aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa last next bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb last next cccc cccc'
      arr = Smess.separate_sms(string)
      arr.length.should == 3
      arr[0].sms_length.should == 159
      arr[1].sms_length.should == 159
      arr[2].sms_length.should == 14
    end
  end

  it 'does not strip gsm characters' do
    @gsm_chars.strip_nongsm_chars.should == @gsm_chars
  end

  it 'folds known umlaut characters' do
    text = @gsm_chars+@folded_to_a
    text.strip_nongsm_chars.should == @gsm_chars+'aaa'
    text.should == @gsm_chars+@folded_to_a
  end

  it 'strips all other characters' do
    (@gsm_chars+@stripped).strip_nongsm_chars.should == @gsm_chars
  end

  it 'certain characters will be uppercase but we can live with that' do
    'Falukorvsgratäng provençale'.strip_nongsm_chars.should == 'Falukorvsgratäng provenÇale'
  end

  it "turns the strings true, True, TRUE... into the boolean value true" do
    Smess.booleanize("true").should == true
    Smess.booleanize("True").should == true
    Smess.booleanize("TRUE").should == true
  end

  it "turns any other (reasonable) input into the boolean value false" do
    Smess.booleanize("TRUTH").should == false
    Smess.booleanize("false").should == false
    Smess.booleanize(nil).should == false
    Smess.booleanize(1).should == false
    Smess.booleanize(["true"]).should == false
  end
end