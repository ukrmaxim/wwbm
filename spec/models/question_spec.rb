require 'rails_helper'

RSpec.describe Question, type: :model do
  context 'validations check' do
    it { should validate_presence_of :level }
    it { should validate_presence_of :text }
    it { should validate_inclusion_of(:level).in_range(0..14) }
    it { should_not allow_value(500).for(:level) }
    it { should allow_value(14).for(:level) }

    subject { FactoryBot.build(:question) }
    it { should validate_uniqueness_of :text }
  end
end
