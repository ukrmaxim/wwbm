# frozen_string_literal: true

require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe Game, type: :model do
  # Пользователь для создания игр
  let(:user) { create(:user) }

  # Игра с прописанными игровыми вопросами
  let(:game_w_questions) do
    create(:game_with_questions, user: user)
  end

  # Группа тестов на работу фабрики создания новых игр
  context 'Game Factory' do
    it 'Game.create_game! new correct game' do
      # Генерим 60 вопросов с 4х запасом по полю level, чтобы проверить работу
      # RANDOM при создании игры.
      generate_questions(60)

      game = nil

      # Создaли игру, обернули в блок, на который накладываем проверки
      expect do
        game = Game.create_game_for_user!(user)
        # Проверка: Game.count изменился на 1 (создали в базе 1 игру)
      end.to change(Game, :count).by(1).and(
        # GameQuestion.count +15
        change(GameQuestion, :count).by(15).and(
          # Game.count не должен измениться
          change(Question, :count).by(0)
        )
      )

      # Проверяем статус и поля
      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)

      # Проверяем корректность массива игровых вопросов
      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  # Тесты на основную игровую логику
  context 'game mechanics' do
    # Правильный ответ должен продолжать игру
    it 'answer correct continues game' do
      # Текущий уровень игры и статус
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(q.correct_answer_key)

      # Перешли на след. уровень
      expect(game_w_questions.current_level).to eq(level + 1)

      # Ранее текущий вопрос стал предыдущим
      expect(game_w_questions.current_game_question).not_to eq(q)

      # Игра продолжается
      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be false
    end

    it '.take money!' do
      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(q.correct_answer_key)
      game_w_questions.take_money!
      prize = game_w_questions.prize

      expect(prize).to be > 0
      expect(game_w_questions.finished?).to be true
      expect(game_w_questions.status).to eq :money
      expect(user.balance).to eq prize
    end
  end

  context '.answer_current_question!' do
    it 'correct answer' do
      q = game_w_questions.current_game_question

      expect(game_w_questions.answer_current_question!(q.correct_answer_key)).to be true
      expect(game_w_questions.current_level).to eq(1)
      expect(game_w_questions.status).to eq(:in_progress)
    end

    it 'wrong answer' do
      expect(game_w_questions.answer_current_question!('a')).to be false
      expect(game_w_questions.finished?).to be true
      expect(game_w_questions.status).to eq(:fail)
    end

    it 'correct answer to the last question' do
      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(q.correct_answer_key)
      game_w_questions.current_level = 15
      game_w_questions.finished_at = Time.now

      expect(game_w_questions.finished?).to be true
      expect(game_w_questions.status).to eq(:won)
    end

    it 'answer after timeout' do
      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(q.correct_answer_key)
      game_w_questions.created_at = Time.now - (Game::TIME_LIMIT + 1)
      game_w_questions.is_failed = true

      expect(game_w_questions.time_out!).to be true
      expect(game_w_questions.status).to eq(:timeout)
    end
  end

  context '.status' do
    before(:each) do
      game_w_questions.finished_at = Time.now
      expect(game_w_questions.finished?).to be true
    end

    it ':won' do
      game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
      expect(game_w_questions.status).to eq(:won)
    end

    it ':fail' do
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:fail)
    end

    it ':timeout' do
      game_w_questions.created_at = Time.now - (Game::TIME_LIMIT + 1)
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:timeout)
    end

    it ':money' do
      expect(game_w_questions.status).to eq(:money)
    end

    it ':in_progress' do
      game_w_questions.finished_at = nil
      expect(game_w_questions.status).to eq(:in_progress)
    end
  end

  context 'access methods' do
    it '.current_game_question' do
      expect(game_w_questions.current_game_question).to eq(game_w_questions.game_questions[0])
    end

    it '.previous_level' do
      expect(game_w_questions.previous_level).to eq(-1)
    end
  end
end
