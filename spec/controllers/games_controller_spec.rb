require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe GamesController, type: :controller do
  # обычный пользователь
  let(:user) { FactoryBot.create(:user) }
  # админ
  let(:admin) { FactoryBot.create(:user, is_admin: true) }
  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }

  # группа тестов для незалогиненного юзера (Анонимус)
  context 'Anon' do
    # из экшена show анона посылаем
    it 'kick from #show' do
      params = { id: game_w_questions.id }
      get :show, params: params

      expect(response.status).not_to eq(200) # статус не 200 ОК
      expect(response).to redirect_to(new_user_session_path) # devise должен отправить на логин
      expect(flash[:alert]).to be # во flash должна быть прописана ошибка
    end

    it "can't create a game" do
      generate_questions(15)
      post :create
      game = assigns(:game)

      expect(response.status).not_to eq(200)
      expect(game).to be nil
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end

    it "can't answer" do
      params = { id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key }
      put :answer, params: params

      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end

    it 'can not take money' do
      params = { id: game_w_questions.id }
      put :take_money, params: params

      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end

    it 'can not use help' do
      params = { id: game_w_questions.id, help_type: :friend_call }
      put :help, params: params

      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end
  end

  # группа тестов на экшены контроллера, доступных залогиненным юзерам
  context 'Usual user' do
    # перед каждым тестом в группе
    before(:each) { sign_in user } # логиним юзера user с помощью спец. Devise метода sign_in

    # юзер может создать новую игру
    it 'creates game' do
      # сперва накидаем вопросов, из чего собирать новую игру
      generate_questions(15)
      post :create
      game = assigns(:game) # вытаскиваем из контроллера поле @game

      # проверяем состояние этой игры
      expect(game.finished?).to be false
      expect(game.user).to eq(user)
      # и редирект на страницу этой игры
      expect(response).to redirect_to(game_path(game))
      expect(flash[:notice]).to be
    end

    # юзер видит свою игру
    it '#show game' do
      params = { id: game_w_questions.id }
      get :show, params: params
      game = assigns(:game) # вытаскиваем из контроллера поле @game

      expect(game.finished?).to be false
      expect(game.user).to eq(user)
      expect(response.status).to eq(200) # должен быть ответ HTTP 200
      expect(response).to render_template('show') # и отрендерить шаблон show
    end

    # юзер отвечает на игру корректно - игра продолжается
    it 'answers correct' do
      # передаем параметр params[:letter]
      params = { id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key }
      put :answer, params: params
      game = assigns(:game)

      expect(game.finished?).to be false
      expect(game.current_level).to be > 0
      expect(response).to redirect_to(game_path(game))
      expect(flash.empty?).to be true # удачный ответ не заполняет flash
    end

    it 'wrong answer' do
      correct_answer_key = game_w_questions.current_game_question.correct_answer_key
      params = { id: game_w_questions.id, letter: (%w[a b c d] - [correct_answer_key]).sample }
      put :answer, params: params
      game = assigns(:game)

      expect(game.finished?).to be true
      expect(game.is_failed).to be true
      expect(response).to redirect_to(user_path(user))
      expect(flash[:alert]).to be
    end

    it "someone else's game" do
      someone_else_game = create(:game_with_questions)
      params = { id: someone_else_game.id }
      get :show, params: params

      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be
    end

    it 'takes money until the end of the game' do
      params = { id: game_w_questions.id }
      game_w_questions.update_attribute(:current_level, 2)
      put :take_money, params: params
      game = assigns(:game)

      expect(game.finished?).to be true
      expect(game.prize).to eq(200)

      user.reload
      expect(user.balance).to eq(200)
      expect(response).to redirect_to(user_path(user))
      expect(flash[:notice]).to be
    end

    it 'create a game while the previous game is not finished' do
      game = assigns(:game)

      expect(game_w_questions.finished?).to be false
      expect { post :create }.to change(Game, :count).by(0)
      expect(game).to be nil
      expect(response).to redirect_to(game_path(game_w_questions))
      expect(flash[:alert]).to be
    end

    it 'uses audience help' do
      params = { id: game_w_questions.id, help_type: :audience_help }

      expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be
      expect(game_w_questions.audience_help_used).to be_falsey

      put :help, params: params
      game = assigns(:game)

      # проверяем, что игра не закончилась, что флажок установился, и подсказка записалась
      expect(game.finished?).to be_falsey
      expect(game.audience_help_used).to be_truthy
      expect(game.current_game_question.help_hash[:audience_help]).to be
      expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
      expect(response).to redirect_to(game_path(game))
    end

    it 'can use fifty_fifty' do
      params = { id: game_w_questions.id, help_type: :fifty_fifty }

      expect(game_w_questions.current_game_question.help_hash[:fifty_fifty]).not_to be
      expect(game_w_questions.fifty_fifty_used).to be false

      put :help, params: params
      game = assigns(:game)
      cgq = game.current_game_question

      expect(game.finished?).to be false
      expect(game.fifty_fifty_used).to be true
      expect(cgq.help_hash[:fifty_fifty]).to be
      expect(cgq.help_hash[:fifty_fifty]).to include(cgq.correct_answer_key)
      expect(game.current_game_question.help_hash[:fifty_fifty].size).to eq(2)
      expect(response).to redirect_to(game_path(game))
    end
  end
end
