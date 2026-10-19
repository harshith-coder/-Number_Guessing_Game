#!/bin/bash

DB_NAME=${DB_NAME:-number_guessing_game}
DB_USER=${DB_USER:-freecodecamp}
PSQL_BIN=${PSQL_BIN:-psql}
PSQL=("$PSQL_BIN" --username="$DB_USER" --dbname="$DB_NAME" -X -q)

"${PSQL[@]}" -c "CREATE TABLE IF NOT EXISTS users (username VARCHAR(22) PRIMARY KEY, games_played INTEGER NOT NULL DEFAULT 0, best_game INTEGER NOT NULL);" >/dev/null 2>&1

echo -n "Enter your username: "
read username
sql_username=${username//\'/\'\'}
user_data=$("${PSQL[@]}" -tA -c "SELECT games_played || '|' || best_game FROM users WHERE username = '$sql_username';")

if [[ -z $user_data ]]; then
  echo "Welcome, $username! It looks like this is your first time here."
else
  IFS='|' read -r games_played best_game <<< "$user_data"
  echo "Welcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
fi

secret_number=$((RANDOM % 1000 + 1))
echo "Guess the secret number between 1 and 1000:"
read guess
guesses=1

while true; do
  if ! [[ $guess =~ ^[0-9]+$ ]]; then
    echo -n "That is not an integer, guess again:"
  elif (( guess == secret_number )); then
    break
  elif (( guess > secret_number )); then
    echo -n "It's lower than that, guess again:"
  else
    echo -n "It's higher than that, guess again:"
  fi

  read guess
  guesses=$((guesses + 1))
done

echo "You guessed it in $guesses tries. The secret number was $secret_number. Nice job!"

if [[ -z $user_data ]]; then
  "${PSQL[@]}" -c "INSERT INTO users (username, games_played, best_game) VALUES ('$sql_username', 1, $guesses);" >/dev/null
else
  "${PSQL[@]}" -c "UPDATE users SET games_played = games_played + 1, best_game = LEAST(best_game, $guesses) WHERE username = '$sql_username';" >/dev/null
fi
