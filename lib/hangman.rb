# frozen_string_literal: true

require 'yaml'
require 'pry'

# mixin
module BasicSerializable
  # should point to a class; change to a different
  # class (e.g. MessagePack, JSON, YAML) to get a different
  # serialization
  @@serializer = YAML

  def serialize
    obj = {}
    instance_variables.map do |var|
      next if %i[@list @answer].include?(var)

      obj[var] = instance_variable_get(var)
    end

    @@serializer.dump obj
  end

  # No actual use to load the game, load_game used insted of this method
  # just for reference
  def unserialize(string)
    obj = @@serializer.parse(string)
    obj.keys.each do |key|
      instance_variable_set(key, obj[key])
    end
  end
end

# Save&Load Game
module SaveGame
  include BasicSerializable
  @@saved = 'saved/saved_game.yml'

  def save_game
    puts 'Do you want to save the game?'
    puts 'press any key to continue or [y]es to save'
    answer = gets.chomp.downcase
    if %w[y yes].include?(answer)
      Dir.mkdir 'saved' unless Dir.exist? 'saved'
      File.open(@@saved, 'w') do |file|
        file.puts serialize
      end
    end
  end

  def load_game
    game = YAML.load_file(@@saved)
    game.keys.each do |key|
      instance_variable_set(key, game[key])
    end
  end
end

# some complementents needed
module Complements
  # list of hangman words
  @@dictionary = File.readlines('5desk.txt')

  # make the hangman output word looks prettier
  def splits_char(word)
    word.split('').map do |char|
      "#{char} "
    end.join
  end
end

# implement the things needed to deal with a word for hangman game
class WordsImplementation
  include Complements

  # take the dictionary word one by one and git rid of the extra spaces then push it an array of hangman words list
  def convert_to_array
    @list = []
    @@dictionary.each do |word|
      @list.push(word.slice(0..-3))
    end
  end

  # select a word between 5 and 12 characters long for the secret word
  def choose_word(list)
    list.select do |word|
      word.length > 5 && word.length < 12
    end.sample.downcase
  end

  # randomely cover some characters for the hangman word game
  def hide_some_charchatar(secret, coverd = [])
    secret.split('').each { |char| coverd.push(char) }
    hidden_char_count = [2, 3].sample
    hidden_char_count.times do
      hidden_index = secret.length - [1, 2, 3, 4, 5, 6, 7].sample
      coverd[hidden_index] = '_'
    end
    coverd.join
  end
end

# main class
class Game < WordsImplementation
  include SaveGame
  def initialize
    puts 'Welcome To Hangman'
    puts 'Press Any Key To Continue Or 0 To Load A Saved Game'
    mode = gets.chomp
    if mode == '0'
      load_game
      game
    else
      @tries = 6
      convert_to_array
      @secret_word = choose_word(@list)
      @coverd_word = hide_some_charchatar(@secret_word)
      game
    end
  end

  def game
    while @tries.positive? && @coverd_word != @secret_word
      puts ''
      puts "You got #{@tries} tries to go"
      puts 'Write Down the complete word'
      puts splits_char(@coverd_word)
      @answer = gets.chomp.downcase
      regex(@answer)
      @tries -= 1
      save_game if @tries < 6
    end
  end

  def regex(check)
    if check !~ /[a-zA-Z]/
      puts 'Invalid entries, Try again!'
      @answer = gets.chomp.downcase
    else
      check_answer(check)
    end
  end

  def check_answer(answer)
    @coverd_word.split('').each do |cover|
      next unless cover == '_'
      next unless @secret_word[@coverd_word.index(cover)] == answer[@coverd_word.index(cover)]

      correct = answer[@coverd_word.index(cover)]
      puts 'Nice! You got a correct letter'
      puts '##############################'
      @coverd_word[@coverd_word.index(cover)] = correct
    end
    puts 'Congrats! you solved it' if @coverd_word == @secret_word
  end
end

player = Game.new
