require 'rails_helper'

RSpec.feature 'User views another player profile', type: :feature do
  let(:user1) { FactoryBot.create :user }
  let(:user2) { FactoryBot.create :user }

  let!(:games) do
    [FactoryBot.create(:game,
                       user: user2,
                       created_at: '30.06.2021 12:27:10',
                       finished_at: '30.06.2021 12:29:20',
                       current_level: 1,
                       prize: 100
    ),
     FactoryBot.create(:game,
                       user: user2,
                       created_at: '30.06.2021 12:30:10',
                       finished_at: '30.06.2021 12:35:20',
                       current_level: 2,
                       prize: 200
     )
    ]
  end

  before(:each) do
    login_as user1
  end

  scenario 'successfully' do

    visit "/users/#{user2.id}"

    expect(page).to have_content "#{user2.name}"
    expect(page).not_to have_content 'Сменить имя и пароль'
    expect(page).to have_content "#{user2.games.first.id}"
    expect(page).to have_content "#{user2.games.last.id}"
    expect(page).to have_content 'деньги'
    expect(page).to have_content "#{I18n.l user2.games.first.created_at, format: :short}"
    expect(page).to have_content "#{I18n.l user2.games.last.created_at, format: :short}"
    expect(page).to have_content "#{user2.games.first.current_level}"
    expect(page).to have_content "#{user2.games.last.current_level}"
    expect(page).to have_content "#{user2.games.first.prize}"
    expect(page).to have_content "#{user2.games.last.prize}"
    expect(page).to have_content '50/50'
    expect(page).to have_css '.fas.fa-phone', count: 2
    expect(page).to have_css '.fas.fa-users', count: 2
  end
end
