require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  before(:each) do
    @user = assign(:user, FactoryBot.create(:user, name: 'Saimon'))

    render
  end

  context 'Login user' do
    before(:each) do
      sign_in(@user)

      render
    end

    it 'renders user name' do
      expect(rendered).to match 'Saimon'
    end

    it 'renders change password' do
      expect(rendered).to match 'Сменить имя и пароль'
    end

    it 'rendered fragments with the game' do
      assign(:games, [FactoryBot.build_stubbed(:game)])
      stub_template 'users/_game.html.erb' => 'Game fragments'

      render

      expect(rendered).to have_content 'Game fragments'
    end
  end

  context 'Anonymous user' do
    it "don't renders change password" do
      expect(rendered).not_to match 'Сменить имя и пароль'
    end
  end
end
