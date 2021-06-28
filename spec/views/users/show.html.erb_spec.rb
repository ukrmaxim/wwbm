require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  let(:user) { FactoryBot.build_stubbed(:user, name: 'Макс', balance: 5000) }

  it 'renders user name' do
    render
    rendered.should contain('Макс')
  end

  it 'renders change password' do
    user.current_user?
    expect(rendered).to match 'Сменить имя и пароль'
  end
end
