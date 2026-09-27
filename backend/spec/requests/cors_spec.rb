require "rails_helper"

RSpec.describe "CORS", type: :request do
  %w[http://localhost:5173 http://127.0.0.1:5173].each do |origin|
    it "allows #{origin}" do
      options "/auth/login", headers: {
        "Origin" => origin,
        "Access-Control-Request-Method" => "POST",
        "Access-Control-Request-Headers" => "authorization,content-type"
      }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Access-Control-Allow-Origin"]).to eq(origin)
      expect(response.headers["Access-Control-Allow-Methods"]).to include("POST")
    end
  end

  it "does not allow an unknown origin" do
    options "/auth/login", headers: {
      "Origin" => "https://untrusted.example",
      "Access-Control-Request-Method" => "POST"
    }

    expect(response.headers["Access-Control-Allow-Origin"]).to be_nil
  end
end
