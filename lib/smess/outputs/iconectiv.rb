module Smess
  class Iconectiv < Ipxus

    private

    def account_key_prefix
      "ICONECTIV"
    end

    # iConectiv asserts that this is all that is still reqquired and that it wont break other carriers.
    # test of major carriers confirm this too... let's see how the small ones do.
    def perform_operator_adaptation(msisdn)
      adapt_for_t_mobile_us msisdn
    end

  end
end