class AddHelpHashToGameQuestion < ActiveRecord::Migration[6.1]
  def change
    add_column :game_questions, :help_hash, :text
  end
end
