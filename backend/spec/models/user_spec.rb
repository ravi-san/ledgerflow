require "rails_helper"

RSpec.describe User, type: :model do
  it "accepts a password with an uppercase letter, number, and special character" do
    user = described_class.new(email: "valid@example.com", password: "Password@1")

    expect(user).to be_valid
  end

  it "rejects a password missing the required character types" do
    user = described_class.new(email: "invalid@example.com", password: "password")

    expect(user).not_to be_valid
    expect(user.errors[:password]).to include("must be at least 8 characters and include an uppercase letter, number, and special character")
  end
end
