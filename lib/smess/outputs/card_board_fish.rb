module Smess
  class CardBoardFish < HttpBase

    def deliver
      request.url = "#{url}?#{params.to_query}"
      http_get request
    end

    attr_accessor :username, :password
    def validate_config
      @username  = config.fetch(:username)
      @password  = config.fetch(:password)
    end

    private

    def url
      "https://sms2.cardboardfish.com:9444/HTTPSMS"
    end

    def params
      @params ||= {
        "S" => "H",
        "UN" => username,
        "P" => password,
        "DA" => sms.to,
        "M" => sms.message.strip_nongsm_chars.encode("ISO-8859-1"),
        "SA" => from,
        "ST" => 5
      }
    end

    def normal_result(response)
      response_code = response.code
      response_code = "0" if response.code.to_s == "200"
      # Successful response
      {
        message_id: message_id,
        response_code: response_code.to_s,
        response: {body: response.body},
        destination_address: sms.to,
        data: result_data
      }
    end

  end
end