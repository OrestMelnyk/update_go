#!/bin/bash

# Последняя версия Go
GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
# Здесь нунжо указать путь к нашим директориям с репозиториями
REPOS_DIR="/path/to/your/repos"

# Здесь проверяем, что go доступен
if ! command -v go &> /dev/null; then
  echo "Go не установлен. Установите Go перед запуском скрипта."
  exit 1
fi

for repo in "$REPOS_DIR"/*; do
  if [ -d "$repo" ]; then
    if [ -f "$repo/go.mod" ]; then
      echo "Обрабатываем $repo..."
      cd "$repo" || continue

      # Здесь обновляем версию Go
      echo "Устанавливаем версию Go $GO_VERSION..."
      go mod edit -go="$GO_VERSION"

      # Здесь обновляем зависимости
      echo "Обновляем зависимости..."
      go get -u ./...
      go mod tidy

      # Здесь проверяем сборку
      echo "Проверяем сборку и тесты..."
      go build ./...
      if [ $? -ne 0 ]; then
        echo "Ошибка сборки в $repo. Останавливаемся."
        exit 1
      fi
      go test ./... || echo "Предупреждение: тесты провалились в $repo"

      # Здесь коммитим изменения
      echo "Коммитим изменения..."
      git add go.mod go.sum
      git commit -m "Update Go to $GO_VERSION and dependencies"
      # Если нужно пушить, раскоментируем значение 
      # git push

      echo "Готово: $repo"
    else
      echo "Пропускаем $repo — файл go.mod не найден."
    fi
  fi
done

echo "Обновление всех репозиториев завершено!"
