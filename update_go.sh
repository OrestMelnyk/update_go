#!/bin/bash

# Последняя версия Go
GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
# Путь к директории с репозиториями
REPOS_DIR="/path/to/your/repos"
# ID таски из YouTrack (передаётся как аргумент, например: ./script.sh TASK-001)
TASK_ID="${1:-TASK_DEFAULT}" # Если аргумент не передан, используется TASK_DEFAULT
BRANCH_NAME="dev/$TASK_ID" # Название ветки, например dev/TASK-001

# Проверяем, что go и git доступны
if ! command -v go &> /dev/null; then
  echo "Go не установлен. Установите Go перед запуском скрипта."
  exit 1
fi
if ! command -v git &> /dev/null; then
  echo "Git не установлен. Установите Git перед запуском скрипта."
  exit 1
fi

for repo in "$REPOS_DIR"/*; do
  if [ -d "$repo" ]; then
    if [ -f "$repo/go.mod" ]; then
      echo "Обрабатываем $repo..."
      cd "$repo" || continue

      # Переключаемся на main
      echo "Переключаемся на ветку main..."
      git checkout main || { echo "Не удалось переключиться на main в $repo"; continue; }

      # Вытягиваем последние изменения
      echo "Обновляем main из удалённого репозитория..."
      git pull || { echo "Не удалось выполнить git pull в $repo"; continue; }

      # Создаём новую ветку из main
      echo "Создаём ветку $BRANCH_NAME..."
      git checkout -b "$BRANCH_NAME" || { echo "Не удалось создать ветку $BRANCH_NAME в $repo"; continue; }

      # Обновляем версию Go
      echo "Устанавливаем версию Go $GO_VERSION..."
      go mod edit -go="$GO_VERSION"

      # Обновляем зависимости
      echo "Обновляем зависимости..."
      go get -u ./...
      go mod tidy

      # Проверяем сборку
      echo "Проверяем сборку и тесты..."
      go build ./...
      if [ $? -ne 0 ]; then
        echo "Ошибка сборки в $repo. Останавливаемся."
        exit 1
      fi
      go test ./... || echo "Предупреждение: тесты провалились в $repo"

      # Коммитим изменения
      echo "Коммитим изменения..."
      git add go.mod go.sum
      git commit -m "Update Go to $GO_VERSION and dependencies for $TASK_ID" || echo "Нечего коммитить в $repo"

      # Пушим новую ветку в origin
      echo "Пушим ветку $BRANCH_NAME в origin..."
      git push -u origin "$BRANCH_NAME" || echo "Ошибка при push в $repo"

      echo "Готово: $repo"
    else
      echo "Пропускаем $repo — файл go.mod не найден."
    fi
  fi
done

echo "Обновление всех репозиториев завершено!"
