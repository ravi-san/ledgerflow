require "rails_helper"
require "support/records"

RSpec.describe "Authentication", type: :request do
  it "returns a token without exposing password data" do
    account = user(email: "secure@example.com", password: "Password@1")

    post "/auth/login", params: { email: account.email, password: "Password@1" }

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body.fetch("token")).to be_present
    expect(body.fetch("user")).to eq("id" => account.id, "email" => account.email)
    expect(response.body).not_to include("password_digest")
  end
end
