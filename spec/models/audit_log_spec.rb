require 'rails_helper'

RSpec.describe AuditLog, type: :model do
  subject(:audit_log) { build(:audit_log) }

  describe "associations" do
    it { is_expected.to belong_to(:user).optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:action) }
    it { is_expected.to validate_presence_of(:resource_type) }
  end

  describe ".record" do
    let(:user) { create(:user, :approved) }
    let(:book) { create(:book) }

    it "creates an audit log entry" do
      expect {
        AuditLog.record(user: user, action: :create, resource: book)
      }.to change(AuditLog, :count).by(1)
    end

    it "records the correct attributes" do
      log = AuditLog.record(user: user, action: :update, resource: book, metadata: { field: "title" })
      expect(log.user).to eq(user)
      expect(log.action).to eq("update")
      expect(log.resource_type).to eq("Book")
      expect(log.resource_id).to eq(book.id)
      expect(log.metadata).to eq({ "field" => "title" })
    end

    it "works with nil user (system actions)" do
      log = AuditLog.record(user: nil, action: :delete, resource: book)
      expect(log.user).to be_nil
    end
  end
end
