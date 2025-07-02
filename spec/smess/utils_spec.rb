# coding: UTF-8
require 'spec_helper'

describe "Smess Utils", iso_id: "7.4" do

  before(:all) do
    @gsm_chars = '@£$¥èéùìòÇ'+"\n"+'Øø'+"\r"+'ÅåΔ_ΦΓΛΩΠΨΣΘΞÆæßÉ !"#¤%&\'()*+,-./0123456789:;<=>?¡ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÑÜ§¿abcdefghijklmnopqrstuvwxyzäöñüà|^€{}[]~\\'
    @folded_to_a = 'áâã'
    @stripped = '“”ÿŸ'
  end

  it "cleans phone numbers" do
    expect("\r\n +(070-123)\n45 67\n".msisdn(46)).to eq('46701234567')
    expect('46701234567'.msisdn(46)).to eq('46701234567')
    expect('44701234567'.msisdn(46)).to eq('44701234567')
    expect('0049701234567'.msisdn(46)).to eq('49701234567')
    expect('(858) 123-4567'.msisdn(46)).to eq('8581234567')
    expect('1234'.msisdn(46)).to eq('')
    expect('BEA790507'.msisdn(46)).to eq('')
  end

  it "cleans phone numbers forcing given country code" do
    expect("\r\n +(070-123)\n45 67\n".msisdn(46, true)).to eq('46701234567')
    expect('46701234567'.msisdn(46, true)).to eq('46701234567')
    expect('0049701234567'.msisdn(46, true)).to eq('49701234567')
    expect('(858) 123-4567'.msisdn(46, true)).to eq('468581234567')
    expect('1234'.msisdn(46, true)).to eq('')
    expect('BEA790507'.msisdn(46, true)).to eq('')
  end

  it 'is idempotent when re-cleaning valid msisdn' do
    expect('46701234567'.msisdn(46).msisdn(46)).to eq('46701234567')
    expect('46701234567'.msisdn(46, true).msisdn(46)).to eq('46701234567')
  end

  it "returns an empty string when cleaning invalid msisdn" do
    expect('hello'.msisdn).to eq('')
  end

  it "turns string empty when cleaning invalid msisdn in place" do
    expect('hello'.msisdn!).to eq('')
  end

  it "can count the length of an sms message in extended String class" do
    string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÑÜ§¿abcdefghijklmnopqrstuvwxyzäöñüà|^€{}[]~\\'
    expect(string.sms_length).to eq(81)
  end

  describe "#split_sms" do
    it "can take a 160 char sms message" do
      string = 'ääää aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa ääää €aaa'
      arr = Smess.split_sms(string)
      expect(arr.length).to eq(1)
      expect(arr[0].sms_length).to eq(160)
    end

    it "can split an sms message into concat parts" do
      # long message that is actually being split
      string = 'ääää aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa ä€ää 28/1. pris 339/mån. Provträna gratis hela vecka 48 på nya. Mer info välkommen till oss. Provträna gratis hela vecka 48 på nya. Mer info välkommen till oss.....'
      arr = Smess.split_sms(string)
      expect(arr.length).to eq(3)
      expect(arr[0].sms_length).to eq(154)
      expect(arr[1].sms_length).to eq(154)
      expect(arr[2].sms_length).to eq(7)
    end

    it "can split with any character at the split point" do
      string = 'ääää aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa a€€€ä aaaa aaaa'
      arr = Smess.split_sms(string)
      expect(arr.length).to eq(2)
      expect(arr[0].sms_length).to eq(153)
      expect(arr[1].sms_length).to eq(15)
    end

    it "can split with any character at the split point, a variation" do
      string = 'ääää aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa äbbä aaaa aaaa'
      arr = Smess.split_sms(string)
      expect(arr.length).to eq(2)
      expect(arr[0].sms_length).to eq(154)
      expect(arr[1].sms_length).to eq(10)
    end

    it "can split to the correct length according to the gsm alphabet" do
      # € and a few other characters are 2-byte characters
      string = 'ääää €€€€ €€€€ €€€€ €€€€ aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa äbbä aaaa aaaa'
      arr = Smess.split_sms(string)
      expect(arr.length).to eq(2)
      expect(arr[0].sms_length).to eq(154)
      expect(arr[1].sms_length).to eq(26)
    end

  end

  describe "#separate_sms" do
    it "can take a 160 char sms message" do
      string = 'ääää aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa ääää €aaa'
      arr = Smess.separate_sms(string)
      expect(arr.length).to eq(1)
      expect(arr[0].sms_length).to eq(160)
    end

    it "separates a string on whitespace to allow sending multiple non-concat messages" do
      string = "aaaaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa last\tnext bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb last next cccc cccc"
      arr = Smess.separate_sms(string)
      expect(arr.length).to eq(3)
      expect(arr[0].sms_length).to eq(156)
      expect(arr[1].sms_length).to eq(159)
      expect(arr[2].sms_length).to eq(14)
    end

    it "calculates the separation point respecting the GSM alphabet" do
      # € and a few other characters are 2-byte characters
      string = 'aaaaaa €€€€ €€€€ aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa aaaa last next bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb bbbb last next cccc cccc'
      arr = Smess.separate_sms(string)
      expect(arr.length).to eq(3)
      expect(arr[0].sms_length).to eq(159)
      expect(arr[1].sms_length).to eq(159)
      expect(arr[2].sms_length).to eq(14)
    end
  end

  it 'does not strip gsm characters' do
    expect(@gsm_chars.strip_nongsm_chars).to eq(@gsm_chars)
  end

  it 'folds known umlaut characters' do
    text = @gsm_chars+@folded_to_a
    expect(text.strip_nongsm_chars).to eq(@gsm_chars+'aaa')
    expect(text).to eq(@gsm_chars+@folded_to_a)
  end

  it 'strips all other characters' do
    expect((@gsm_chars+@stripped).strip_nongsm_chars).to eq(@gsm_chars)
  end

  it 'certain characters will be uppercase but we can live with that' do
    expect('Falukorvsgratäng provençale'.strip_nongsm_chars).to eq('Falukorvsgratäng provenÇale')
  end

  it "turns the strings true, True, TRUE... into the boolean value true" do
    expect(Smess.booleanize("true")).to eq(true)
    expect(Smess.booleanize("True")).to eq(true)
    expect(Smess.booleanize("TRUE")).to eq(true)
  end

  it "turns any other (reasonable) input into the boolean value false" do
    expect(Smess.booleanize("TRUTH")).to eq(false)
    expect(Smess.booleanize("false")).to eq(false)
    expect(Smess.booleanize(nil)).to eq(false)
    expect(Smess.booleanize(1)).to eq(false)
    expect(Smess.booleanize(["true"])).to eq(false)
  end
end
